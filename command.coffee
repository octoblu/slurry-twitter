_               = require 'lodash'
MeshbluConfig   = require 'meshblu-config'
path            = require 'path'
Slurry            = require 'slurry-core'
OctobluStrategy = require 'slurry-core/octoblu-strategy'
ApiStrategy     = require './src/api-strategy'
MessageHandler  = require './src/message-handler'
ConfigureHandler = require './src/configure-handler'

MISSING_SERVICE_URL = 'Missing required environment variable: SLURRY_TWITTER_SERVICE_URL'
MISSING_MANAGER_URL = 'Missing required environment variable: SLURRY_TWITTER_MANAGER_URL'
MISSING_APP_OCTOBLU_HOST = 'Missing required environment variable: APP_OCTOBLU_HOST'

class Command
  getOptions: =>
    throw new Error MISSING_SERVICE_URL if _.isEmpty process.env.SLURRY_TWITTER_SERVICE_URL
    throw new Error MISSING_MANAGER_URL if _.isEmpty process.env.SLURRY_TWITTER_MANAGER_URL
    throw new Error MISSING_APP_OCTOBLU_HOST if _.isEmpty process.env.APP_OCTOBLU_HOST

    meshbluConfig   = new MeshbluConfig().toJSON()
    apiStrategy     = new ApiStrategy process.env
    octobluStrategy = new OctobluStrategy process.env, meshbluConfig

    return {
      apiStrategy:     apiStrategy
      deviceType:      'slurry:twitter'
      disableLogging:  process.env.DISABLE_LOGGING == "true"
      meshbluConfig:   meshbluConfig
      messageHandler:  new MessageHandler
      configureHandler: new ConfigureHandler
      octobluStrategy: octobluStrategy
      port:            process.env.PORT || 80
      appOctobluHost:  process.env.APP_OCTOBLU_HOST
      serviceUrl:      process.env.SLURRY_TWITTER_SERVICE_URL
      userDeviceManagerUrl: process.env.SLURRY_TWITTER_MANAGER_URL
      staticSchemasPath: process.env.SLURRY_TWITTER_STATIC_SCHEMAS_PATH
    }

  run: =>
    server = new Slurry @getOptions()
    server.run (error) =>
      throw error if error?

      {address,port} = server.address()
      console.log "Server listening on #{address}:#{port}"

command = new Command()
command.run()
