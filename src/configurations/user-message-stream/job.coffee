http          = require 'http'
_             = require 'lodash'
Twitter       = require 'twitter'
MeshbluHttp   = require 'meshblu-http'
MeshbluConfig = require 'meshblu-config'
SlurryStream  = require 'slurry-core/slurry-stream'

class UserMessageStream
  constructor: ({@encrypted, @auth, @userDeviceUuid}) ->
    meshbluConfig = new MeshbluConfig({@auth}).toJSON()
    meshbluHttp = new MeshbluHttp meshbluConfig
    @twitter = new Twitter({
      consumer_key:        process.env.SLURRY_TWITTER_TWITTER_CLIENT_ID
      consumer_secret:     process.env.SLURRY_TWITTER_TWITTER_CLIENT_SECRET
      access_token_key:    @encrypted.secrets.credentials.token
      access_token_secret: @encrypted.secrets.credentials.secret
    })
    @_throttledMessage = _.throttle meshbluHttp.message, 500, leading: true, trailing: false

  do: ({slurry}, callback) =>
    metadata =
      track: _.join(slurry.track, ',')
      follow: _.join(slurry.follow, ',')

    @twitter.stream 'user', metadata, (stream) =>
      slurryStream = new SlurryStream
      slurryStream.destroy = =>
        stream.destroy()

      stream.on 'data', (event) =>
        message =
          devices: ['*']
          metadata: metadata
          data: event

        @_throttledMessage message, as: @userDeviceUuid, (error) =>
          slurryStream.emit 'error', error if error?

      stream.on 'error', (error) =>
        slurryStream.emit 'error', error

      return callback null, slurryStream

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = UserMessageStream
