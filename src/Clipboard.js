"use strict";

export const _writeText = function _writeText({ navigator, text }) {
  navigator.clipboard.writeText(text);
}
