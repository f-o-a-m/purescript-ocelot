module UIGuide.Component.Tab where

import Prelude

import Ocelot.Block.NavigationTab as NavigationTab
import Ocelot.Block.Format as Format
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import UIGuide.Block.Backdrop as Backdrop
import UIGuide.Block.Documentation as Documentation

type State = Unit

data Query (a :: Type)
type Action = Unit

type Input = Unit

type Message = Void


component :: ∀ m. H.Component Query Input Message m
component =
  H.mkComponent
    { initialState: const unit
    , render
    , eval: H.mkEval H.defaultEval
    }
  where
    render :: State -> H.ComponentHTML Action () m
    render _ =
      HH.div_
      [ Documentation.block_
          { header: "Tabs"
          , subheader: "Tabs for navigating, eg. between form pages"
          }
          [ Backdrop.backdrop_
              [ HH.h3
                [ HP.classes Format.captionClasses ]
                [ HH.text "Standard Tabs" ]
              , HH.div
                  [ HP.class_ (HH.ClassName "bg-black-10 flex items-center justify-center h-full w-full") ]
                  [ NavigationTab.navigationTabs_ (tabConfig defaultTabs) ]
              ]
          , Backdrop.backdrop_
              [ HH.h3
                [ HP.classes Format.captionClasses ]
                [ HH.text "Tabs with Errors" ]
              , HH.div
                  [ HP.class_ (HH.ClassName "bg-black-10 flex items-center justify-center h-full w-full") ]
                  [ NavigationTab.navigationTabs_ (tabConfig errorTabs) ]
              ]
          ]
      ]
      where
        defaultTabs :: Array (NavigationTab.Tab Boolean)
        defaultTabs =
          [ { name: "Accounts & Spend", link: "#", page: true, errors: 0 }
          , { name: "Automatic Optimization", link: "#", page: false, errors: 0 }
          , { name: "Creative", link: "#", page: false, errors: 0 }
          ]

        errorTabs :: Array (NavigationTab.Tab Boolean)
        errorTabs =
          [ { name: "Accounts & Spend", link: "#", page: true, errors: 0 }
          , { name: "Automatic Optimization", link: "#", page: false, errors: 1 }
          , { name: "Creative", link: "#", page: false, errors: 0 }
          ]

        tabConfig :: Array (NavigationTab.Tab Boolean) -> NavigationTab.TabConfig Boolean
        tabConfig tabs =
          { tabs: tabs
          , activePage: true
          }
