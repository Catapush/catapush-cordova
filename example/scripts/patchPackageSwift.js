#!/usr/bin/env node
/**
 * Cordova before_build hook for iOS.
 *
 * Workaround for a bug in cordova-ios 8: SwiftPackage.js uses a regex that
 * only matches enum-style platform versions (.iOS(.v13)) but the generated
 * Package.swift uses string-style (.iOS("12.0")), so updateDeploymentTarget()
 * never fires. This script applies the correct deployment target manually.
 *
 * See: https://github.com/apache/cordova-ios/issues/XXXX
 */

const fs = require('fs');
const path = require('path');

module.exports = function (context) {
    if (!context.opts.platforms.includes('ios')) return;

    const pkgPath = path.join(
        context.opts.projectRoot,
        'platforms', 'ios', 'packages', 'cordova-ios-plugins', 'Package.swift'
    );

    if (!fs.existsSync(pkgPath)) return;

    // Read deployment target from config.xml
    const ConfigParser = context.requireCordovaModule('cordova-common').ConfigParser;
    const cfg = new ConfigParser(path.join(context.opts.projectRoot, 'config.xml'));
    const target = cfg.getPreference('deployment-target', 'ios') || '14.0';

    let content = fs.readFileSync(pkgPath, 'utf8');
    const updated = content
        .replace(/\.iOS\("[^"]+"\)/, `.iOS("${target}")`)
        .replace(/\.macCatalyst\("[^"]+"\)/, `.macCatalyst("${target}")`);

    if (updated !== content) {
        fs.writeFileSync(pkgPath, updated, 'utf8');
        console.log(`[patchPackageSwift] Set deployment target to ${target} in Package.swift`);
    }
};
