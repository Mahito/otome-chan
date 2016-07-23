module.exports = (robot) ->
  robot.respond /(ame|あめ|雨)/i, (res) ->
    res.send "雨の様子やで"

    fs = require('fs')
    phantom = require('phantom')
    sitepage = null
    phInstance = null
    fileName = 'ame.png'

    phantom.create()
        .then (instance) ->
            phInstance = instance
            return instance.createPage()
        .then (page) ->
            sitepage = page
            sitepage.property 'viewportSize', { width: 1024, height: 768 }
            sitepage.property 'clipRect', { top: 70, left: 10, width: 772, height: 482 }
            return sitepage.open 'http://tokyo-ame.jwa.or.jp/'
        .then (status) ->
            return sitepage.render fileName
        .then (result) ->
            webClient = require('@slack/client').WebClient
            token = process.env.HUBOT_SLACK_TOKEN || ''
            web = new webClient token
            opts = {
              file: fs.createReadStream(fileName),
              channels: res.envelope.room
            }
            web.files.upload fileName, opts, (err, resp) ->
              res.send "upしたで"
            sitepage.close();
            phInstance.exit();
        .catch (error) ->
            res.send error
            phInstance.exit()
