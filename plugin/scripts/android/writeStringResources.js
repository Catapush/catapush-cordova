/**
 * Cordova hook: after_plugin_install, before_build (Android)
 *
 * Writes Catapush configuration string resources to
 * platforms/android/app/src/main/res/values/strings.xml.
 *
 * In cordova-android 15, the config-file target="res/values/strings.xml"
 * mechanism does not create the file because cordova-android no longer
 * includes strings.xml in its project template. This hook writes the
 * strings directly, reading variable values from android.json.
 */

module.exports = function (context) {
  var fs = require('fs')
  var path = require('path')

  var platformRoot = path.join(context.opts.projectRoot, 'platforms', 'android')
  var androidJsonPath = path.join(platformRoot, 'android.json')

  if (!fs.existsSync(androidJsonPath)) {
    return // android platform not added yet
  }

  var androidJson = JSON.parse(fs.readFileSync(androidJsonPath, 'utf8'))
  var pluginVars =
    androidJson.installed_plugins && androidJson.installed_plugins['catapush-cordova-sdk']

  if (!pluginVars) {
    return // plugin not installed yet
  }

  var stringsXmlPath = path.join(
    platformRoot,
    'app',
    'src',
    'main',
    'res',
    'values',
    'strings.xml'
  )
  var stringsDir = path.dirname(stringsXmlPath)

  if (!fs.existsSync(stringsDir)) {
    fs.mkdirSync(stringsDir, { recursive: true })
  }

  // Read existing strings (from any other plugins/app) to avoid overwriting them
  var existingStrings = {}
  if (fs.existsSync(stringsXmlPath)) {
    var existingContent = fs.readFileSync(stringsXmlPath, 'utf8')
    var re = /<string name="([^"]+)"[^>]*>([^<]*)<\/string>/g
    var m
    while ((m = re.exec(existingContent)) !== null) {
      existingStrings[m[1]] = m[2]
    }
  }

  // Merge Catapush strings (overwrite if already present)
  existingStrings['catapush_notification_channel_id'] =
    pluginVars['NOTIFICATION_CHANNEL_ID'] || 'com.catapush.cordova.sdk.channel'
  existingStrings['catapush_notification_channel_name'] =
    pluginVars['NOTIFICATION_CHANNEL_NAME'] || 'Notification channel'
  existingStrings['catapush_notification_title'] =
    pluginVars['NOTIFICATION_TITLE'] || ' '
  existingStrings['catapush_notification_icon_res'] =
    pluginVars['NOTIFICATION_ICON_RES'] || 'ic_stat_notify'
  existingStrings['catapush_notification_color_hex'] =
    pluginVars['NOTIFICATION_COLOR_HEX'] || '#50BFF7'

  var entries = Object.keys(existingStrings)
    .map(function (name) {
      return (
        '    <string name="' + name + '" translatable="false">' + existingStrings[name] + '</string>'
      )
    })
    .join('\n')

  var xml =
    "<?xml version='1.0' encoding='utf-8'?>\n<resources>\n" + entries + '\n</resources>\n'

  fs.writeFileSync(stringsXmlPath, xml, 'utf8')
  console.log('[writeStringResources] Wrote Catapush string resources to ' + stringsXmlPath)
}
