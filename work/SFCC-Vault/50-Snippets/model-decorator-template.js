'use strict';

/**
 * File: cartridges/app_<client>_storefront/cartridge/models/decorators/<name>.js
 * Snippet: SFRA model decorator
 *
 * Usage in a model:
 *   var <name>Decorator = require('*\/cartridge/models/decorators/<name>');
 *   <name>Decorator(this, apiProduct);
 */

/**
 * @param {Object} object - target model
 * @param {dw.catalog.Product} apiProduct - or other dw API object
 */
module.exports = function (object, apiProduct) {
    Object.defineProperty(object, '<propertyName>', {
        enumerable: true,
        value: (function () {
            // derive value from apiProduct; keep this pure + cheap
            return null;
        }())
    });
};
