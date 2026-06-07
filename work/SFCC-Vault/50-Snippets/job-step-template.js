'use strict';

/**
 * File: cartridges/int_<feature>/cartridge/scripts/jobs/<jobname>.js
 * Snippet: SFCC job step (chunk-oriented and task-oriented variants)
 *
 * Register the step in: cartridges/int_<feature>/cartridge/steptypes.json
 */

var Logger = require('dw/system/Logger').getLogger('<feature>', '<jobname>');
var Status = require('dw/system/Status');

// --- TASK-ORIENTED step: single function, returns Status ---
function execute(parameters, stepExecution) {
    try {
        // do work
        return new Status(Status.OK, 'OK', 'Step completed');
    } catch (e) {
        Logger.error('Step failed: {0}\n{1}', e.message, e.stack);
        return new Status(Status.ERROR, 'ERROR', e.message);
    }
}

// --- CHUNK-ORIENTED step: total / read / process / write ---
var iterator;

function beforeStep(parameters, stepExecution) {
    // open iterator, etc.
}

function getTotalCount(parameters, stepExecution) {
    return 0; // estimated total for progress
}

function read(parameters, stepExecution) {
    // return next item, or undefined when done
    return undefined;
}

function process(item, parameters, stepExecution) {
    // transform / skip (return null to skip)
    return item;
}

function write(items, parameters, stepExecution) {
    // persist the chunk
}

function afterStep(success, parameters, stepExecution) {
    // close resources; success is boolean
}

module.exports = {
    execute: execute,
    beforeStep: beforeStep,
    getTotalCount: getTotalCount,
    read: read,
    process: process,
    write: write,
    afterStep: afterStep
};
