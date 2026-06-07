'use strict';

/**
 * File: cartridges/int_<feature>/cartridge/scripts/services/<serviceName>.js
 * Snippet: LocalServiceRegistry HTTP service with retry-aware structure
 *
 * BM configuration:
 *  - Service ID:        <feature>.http.<serviceName>
 *  - Credential ID:     <feature>.http.<serviceName>.cred
 *  - Profile ID:        <feature>.http.<serviceName>.profile
 *    (timeout, max-retries, throttling go on the profile)
 */

var LocalServiceRegistry = require('dw/svc/LocalServiceRegistry');
var Logger = require('dw/system/Logger').getLogger('<feature>', '<serviceName>');

var SERVICE_ID = '<feature>.http.<serviceName>';

module.exports.create = function () {
    return LocalServiceRegistry.createService(SERVICE_ID, {
        createRequest: function (svc, params) {
            var cred = svc.getConfiguration().getCredential();
            svc.setURL(cred.getURL() + (params && params.path ? params.path : ''));
            svc.setRequestMethod((params && params.method) || 'GET');
            svc.addHeader('Content-Type', 'application/json');
            svc.addHeader('Accept', 'application/json');

            // OAuth bearer, basic auth, etc. — pick one
            // svc.setAuthentication('BASIC');
            // svc.addHeader('Authorization', 'Bearer ' + getToken());

            return params && params.body ? JSON.stringify(params.body) : null;
        },

        parseResponse: function (svc, response) {
            try {
                return JSON.parse(response.text);
            } catch (e) {
                Logger.error('parseResponse failed: {0}', e.message);
                throw e;
            }
        },

        filterLogMessage: function (msg) {
            // strip secrets before they hit the log
            return msg.replace(/("?(?:authorization|password|token)"?\s*[:=]\s*")[^"]+(")/gi, '$1***$2');
        },

        getRequestLogMessage: function (request) { return request; },
        getResponseLogMessage: function (response) { return response.text; }
    });
};
