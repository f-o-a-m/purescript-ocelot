module UIGuide.Component.ExpansionCards where

import Prelude

import Data.Array (head, take)
import Data.Lens (Lens', over)
import Data.Lens.Record (prop)
import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Network.RemoteData (RemoteData(..))
import Ocelot.Block.Card as Card
import Ocelot.Block.Expandable as Expandable
import Ocelot.Block.FormField as FormField
import Ocelot.Block.Format as Format
import Ocelot.Block.Icon as Icon
import Ocelot.Block.ItemContainer (boldMatches) as IC
import Ocelot.Block.Toggle as Toggle
import Ocelot.HTML.Properties (css)
import Ocelot.Typeahead as TA
import Type.Proxy (Proxy(..))
import UIGuide.Block.Backdrop as Backdrop
import UIGuide.Block.Documentation as Documentation
import UIGuide.Utility.Async as Async


----------
-- Component Types

type State =
  { singleLocation :: Expandable.Status
  , singleUser :: Expandable.Status
  , multiLocation :: Expandable.Status
  , multiUser :: Expandable.Status
  }

data Query (a :: Type)
data Action
  = ToggleCard (Lens' State Expandable.Status)
  | Initialize

----------
-- Child paths

type ChildSlot =
  ( cp1 :: TA.Slot Action Maybe Async.User Int
  , cp2 :: TA.Slot Action Array Async.User Int
  , cp3 :: TA.Slot Action Maybe Async.Location Int
  , cp4 :: TA.Slot Action Array Async.Location Int
  )

_cp1 = Proxy :: Proxy "cp1"
_cp2 = Proxy :: Proxy "cp2"
_cp3 = Proxy :: Proxy "cp3"
_cp4 = Proxy :: Proxy "cp4"

----------
-- Component definition

component :: ∀ m
  . MonadAff m
 => H.Component Query Unit Void m
component =
  H.mkComponent
  { initialState
  , render
  , eval: H.mkEval $ H.defaultEval
    { initialize = Just Initialize
    , handleAction = handleAction
    }
  }
  where
    initialState _ =
      { singleLocation: Expandable.Collapsed
      , singleUser: Expandable.Expanded
      , multiLocation: Expandable.Collapsed
      , multiUser: Expandable.Expanded
      }
    -- For the sake of testing and visual demonstration, we'll just render
    -- out a bunch of selection variants in respective slots
    render
      :: State
      -> H.ComponentHTML Action ChildSlot m
    render = cnDocumentationBlocks

    handleAction :: Action -> H.HalogenM State Action ChildSlot Void m Unit
    handleAction = case _ of
      ToggleCard lens -> do
        st <- H.get
        H.put (over lens not st)

      Initialize -> do
        _ <- H.queryAll _cp1 $ H.mkTell $ TA.ReplaceItems Loading
        _ <- H.queryAll _cp2 $ H.mkTell $ TA.ReplaceItems Loading
        _ <- H.queryAll _cp3 $ H.mkTell $ TA.ReplaceItems Loading
        _ <- H.queryAll _cp4 $ H.mkTell $ TA.ReplaceItems Loading

        remoteLocations <- H.liftAff $ Async.loadFromSource Async.locations ""
        _ <- case remoteLocations of
          items@(Success _) -> do
            _ <- H.queryAll _cp3 $ H.mkTell $ TA.ReplaceItems items
            _ <- H.queryAll _cp4 $ H.mkTell $ TA.ReplaceItems items
            pure unit
          _ -> pure unit

        remoteUsers <- H.liftAff $ Async.loadFromSource Async.users ""
        _ <- case remoteUsers of
          items@(Success _) -> do
            _ <- H.queryAll _cp1 $ H.mkTell $ TA.ReplaceItems items
            _ <- H.queryAll _cp2 $ H.mkTell $ TA.ReplaceItems items
            pure unit
          _ -> pure unit

        selectedLocations <- H.liftAff $ Async.loadFromSource Async.locations "an"
        _ <- case selectedLocations of
          Success xs -> do
            _ <- H.tell _cp3 1 $ TA.ReplaceSelected (head xs)
            _ <- H.tell _cp4 3 $ TA.ReplaceSelected (take 4 xs)
            pure unit
          _ -> pure unit

        selectedUsers <- H.liftAff $ Async.loadFromSource Async.users "an"
        case selectedUsers of
          Success xs -> do
            _ <- H.tell _cp1 1 $ TA.ReplaceSelected (head xs)
            _ <- H.tell _cp2 3 $ TA.ReplaceSelected (take 4 xs)
            pure unit
          _ -> pure unit


----------
-- HTML

_singleLocation :: Lens' State Expandable.Status
_singleLocation = prop (Proxy :: Proxy "singleLocation")

_singleUser :: Lens' State Expandable.Status
_singleUser = prop (Proxy :: Proxy "singleUser")

_multiLocation :: Lens' State Expandable.Status
_multiLocation = prop (Proxy :: Proxy "multiLocation")

_multiUser :: Lens' State Expandable.Status
_multiUser = prop (Proxy :: Proxy "multiUser")

cnDocumentationBlocks :: ∀ m
  . MonadAff m
 => State
 -> H.ComponentHTML Action ChildSlot m
cnDocumentationBlocks st =
  HH.div_
    [ Documentation.customBlock_
      { header: "Expansion Cards"
      , subheader: "Hide sections of UI behind a click, or allow them to be hidden with one."
      }
      [ Documentation.callout_
        [ Backdrop.backdropWhite
          [ css "flex-col" ]
          [ Format.subHeading_
            [ Icon.info [ css "text-yellow pr-2" ]
            , HH.text "Animation Warning"
            ]
          , Format.p_
            [ HH.text "If the expansion card or any of its parents have "
            , HH.code_ [ HH.text "overflow: hidden" ]
            , HH.text " set, it may cause the collapse and expand animations to fail in some browsers, resulting in a rougher transition."
            ]
          ]
        ]
      , Documentation.callout_
        [ Backdrop.backdrop_
          [ Backdrop.content_
            [ Card.card_
              [ Expandable.heading
                [ HE.onClick \_ -> ToggleCard _singleLocation
                , Expandable.status st.singleLocation
                ]
                [ Format.subHeading_ [ HH.text "Locations" ]
                , Format.p_ [ HH.text "Here are some location typeaheads for you. Initially hidden from view since you may not be interested in them." ]
                ]
              , Expandable.content_
                st.singleLocation
                [ FormField.field_
                  { label: HH.text "Primary Location"
                  , helpText: [ HH.text "Search your favorite destination." ]
                  , error: []
                  , inputId: "location"
                  }
                  [ HH.slot_ _cp3 0 TA.single
                    ( TA.asyncSingle
                      { renderFuzzy: HH.span_ <<< IC.boldMatches "name"
                      , itemToObject: Async.locationToObject
                      , async: Async.loadFromSource Async.locations
                      }
                      [ HP.placeholder "Search locations..."
                      , HP.id "location"
                      ]
                    )
                  ]
                , FormField.field_
                  { label: HH.text "Secondary Location"
                  , helpText: [ HH.text "Search your favorite destination." ]
                  , error: []
                  , inputId: "location-hydrated"
                  }
                  [ HH.slot_ _cp3 1 TA.single
                    ( TA.asyncSingle
                      { renderFuzzy: HH.span_ <<< IC.boldMatches "name"
                      , itemToObject: Async.locationToObject
                      , async: Async.loadFromSource Async.locations
                      }
                      [ HP.placeholder "Search locations..."
                      , HP.id "location-hydrated"
                      ]
                    )
                  ]
                ]
              ]
            ]
          , Backdrop.content_
            [ Card.card_
              [ Expandable.heading
                [ HE.onClick \_ -> ToggleCard _singleUser
                , Expandable.status st.singleUser
                ]
                [ Format.subHeading_ [ HH.text "Users" ] ]
              , Expandable.content_
                st.singleUser
                [ FormField.field_
                  { label: HH.text "Primary User"
                  , helpText: [ HH.text "Search your favorite companion." ]
                  , error: []
                  , inputId: "user"
                  }
                  [ HH.slot_ _cp1 0 TA.single
                    ( TA.asyncSingle
                      { renderFuzzy: Async.renderFuzzyUser
                      , itemToObject: Async.userToObject
                      , async: Async.loadFromSource Async.users
                      }
                      [ HP.placeholder "Search users..."
                      , HP.id "user"
                      ]
                    )
                  ]
                , FormField.field_
                  { label: HH.text "Secondary User"
                  , helpText: [ HH.text "Search your favorite companion." ]
                  , error: []
                  , inputId: "user-hydrated"
                  }
                  [ HH.slot_ _cp1 1 TA.single
                    ( TA.asyncSingle
                      { renderFuzzy: Async.renderFuzzyUser
                      , itemToObject: Async.userToObject
                      , async: Async.loadFromSource Async.users
                      }
                      [ HP.placeholder "Search users..."
                      , HP.id "user-hydrated"
                      ]
                    )
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    , Documentation.block_
      { header: "Expansion Cards - Custom"
      , subheader: "Take control of how the expansion toggle looks and behaves."
      }
      [ Backdrop.backdrop_
        [ Backdrop.content_
          [ Card.card_
            [ Format.subHeading_
              [ HH.text "Optimization Rules Engine" ]
            , Format.p_
              [ HH.text "Unlock even more optimizations with customizable controls and preferences. You'll be able to tailor optimizations with greater precision towards achieving your goal. Best suited for campaigns with flexible budgets per campaign, instead use the budget optimization setting located on the Spend Tab off the Campaign Form." ]
            , FormField.field_
              { label: HH.text "Enabled"
              , helpText: []
              , error: []
              , inputId: "enable-locations"
              }
              [ Toggle.toggle
                [ HP.id "enable-locations"
                , HP.checked
                  $ Expandable.toBoolean st.multiLocation
                , HE.onChange \_ -> ToggleCard _multiLocation
                ]
              ]
            , Expandable.content_
              st.multiLocation
              [ FormField.field_
                { label: HH.text "Targeted Locations"
                , helpText: [ HH.text "Search your top destinations." ]
                , error: []
                , inputId: "locations"
                }
                [ HH.slot_ _cp4 0 TA.multi
                  ( TA.asyncMulti
                    { renderFuzzy: HH.span_ <<< IC.boldMatches "name"
                    , itemToObject: Async.locationToObject
                    , async: Async.loadFromSource Async.locations
                    }
                    [ HP.placeholder "Search locations..."
                    , HP.id "locations"
                    ]
                  )
                ]
              , FormField.field_
                { label: HH.text "Excluded Locations"
                , helpText: [ HH.text "Search your top destinations." ]
                , error: []
                , inputId: "locations"
                }
                [ HH.slot_ _cp4 1 TA.multi
                  ( TA.asyncMulti
                    { renderFuzzy: HH.span_ <<< IC.boldMatches "name"
                    , itemToObject: Async.locationToObject
                    , async: Async.loadFromSource Async.locations
                    }
                    [ HP.placeholder "Search locations..."
                    , HP.id "locations"
                    ]
                  )
                ]
              ]
            ]
          ]
        , Backdrop.content_
          [ Card.card_
            [ Format.subHeading_
              [ HH.text "Optimization Rules Engine" ]
            , Format.p_
              [ HH.text "Unlock even more optimizations with customizable controls and preferences. You'll be able to tailor optimizations with greater precision towards achieving your goal. Best suited for campaigns with flexible budgets per campaign, instead use the budget optimization setting located on the Spend Tab off the Campaign Form." ]
            , FormField.field_
              { label: HH.text "Enabled"
              , helpText: []
              , error: []
              , inputId: "enable-users"
              }
              [ Toggle.toggle
                [ HP.id "enable-users"
                , HP.checked
                  $ Expandable.toBoolean st.multiUser
                , HE.onChange \_ -> ToggleCard _multiUser
                ]
              ]
            , Expandable.content_
              st.multiUser
              [ FormField.field_
                { label: HH.text "Targeted Users"
                , helpText: [ HH.text "Search your top companions." ]
                , error: []
                , inputId: "users"
                }
                [ HH.slot_ _cp2 0 TA.multi
                  ( TA.asyncMulti
                    { renderFuzzy: Async.renderFuzzyUser
                    , itemToObject: Async.userToObject
                    , async: Async.loadFromSource Async.users
                    }
                    [ HP.placeholder "Search users..."
                    , HP.id "users"
                    ]
                  )
                ]
              , FormField.field_
                { label: HH.text "Excluded Users"
                , helpText: [ HH.text "Search your top companions." ]
                , error: []
                , inputId: "users-hydrated"
                }
                [ HH.slot_ _cp2 1 TA.multi
                  ( TA.asyncMulti
                    { renderFuzzy: Async.renderFuzzyUser
                    , itemToObject: Async.userToObject
                    , async: Async.loadFromSource Async.users
                    }
                    [ HP.placeholder "Search users..."
                    , HP.id "users-hydrated"
                    ]
                  )
                ]
              ]
            ]
          ]
        ]
      ]
    ]
