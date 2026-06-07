'use strict';

/**
 * File: cartridges/app_<client>_storefront/cartridge/controllers/<Name>.js
 * Snippet: SFRA controller skeleton (append / prepend / replace)
 *
 * Rename:
 *  - <Name>           → your controller (e.g. Account, Cart)
 *  - <route>          → route name
 *  - <basecontroller> → name of base controller you're extending
 */

var server = require('server');
server.extend(module.superModule);

// --- APPEND: add behavior AFTER base ---
server.append('<route>', function (req, res, next) {
    var viewData = res.getViewData();
    // mutate viewData here
    res.setViewData(viewData);
    next();
});

// --- PREPEND: short-circuit or set state BEFORE base ---
server.prepend('<route>', function (req, res, next) {
    // e.g. validate, redirect, set CSRF
    next();
});

// --- REPLACE: full rewrite (use sparingly — upgrade pain) ---
// server.replace('<route>', server.middleware.https, function (req, res, next) {
//     res.render('<template>', { /* view data */ });
//     next();
// });

module.exports = server.exports();
