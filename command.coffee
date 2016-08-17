_                = require 'lodash'
MeshbluConfig    = require 'meshblu-config'
path             = require 'path'
Slurry           = require 'slurry-core'
OctobluStrategy  = require 'slurry-core/octoblu-strategy'
MessageHandler   = require 'slurry-core/message-handler'
ConfigureHandler = require 'slurry-core/configure-handler'
ApiStrategy      = require './src/api-strategy'
SlurrySpreader   = require 'slurry-spreader'

MISSING_SERVICE_URL = 'Missing required environment variable: SLURRY_TWITTER_SERVICE_URL'
MISSING_MANAGER_URL = 'Missing required environment variable: SLURRY_TWITTER_MANAGER_URL'
MISSING_APP_OCTOBLU_HOST = 'Missing required environment variable: APP_OCTOBLU_HOST'
MISSING_SPREADER_REDIS_URI   = 'Missing required environment variable: SLURRY_SPREADER_REDIS_URI'
MISSING_SPREADER_NAMESPACE   = 'Missing required environment variable: SLURRY_SPREADER_NAMESPACE'

class Command
  getOptions: =>
    throw new Error MISSING_SPREADER_REDIS_URI if _.isEmpty process.env.SLURRY_SPREADER_REDIS_URI
    throw new Error MISSING_SPREADER_NAMESPACE if _.isEmpty process.env.SLURRY_SPREADER_NAMESPACE
    throw new Error MISSING_SERVICE_URL if _.isEmpty process.env.SLURRY_TWITTER_SERVICE_URL
    throw new Error MISSING_MANAGER_URL if _.isEmpty process.env.SLURRY_TWITTER_MANAGER_URL
    throw new Error MISSING_APP_OCTOBLU_HOST if _.isEmpty process.env.APP_OCTOBLU_HOST

    meshbluConfig   = new MeshbluConfig().toJSON()
    apiStrategy     = new ApiStrategy process.env
    octobluStrategy = new OctobluStrategy process.env, meshbluConfig
    @slurrySpreader  = new SlurrySpreader
      redisUri: process.env.SLURRY_SPREADER_REDIS_URI
      namespace: process.env.SLURRY_SPREADER_NAMESPACE

    jobsPath = path.join __dirname, 'src/jobs'
    configurationsPath = path.join __dirname, 'src/configurations'

    return {
      apiStrategy:     apiStrategy
      deviceType:      'slurry:twitter'
      disableLogging:  process.env.DISABLE_LOGGING == "true"
      meshbluConfig:   meshbluConfig
      messageHandler:  new MessageHandler {jobsPath}
      configureHandler: new ConfigureHandler {@slurrySpreader, configurationsPath}
      octobluStrategy: octobluStrategy
      port:            process.env.PORT || 80
      appOctobluHost:  process.env.APP_OCTOBLU_HOST
      serviceUrl:      process.env.SLURRY_TWITTER_SERVICE_URL
      userDeviceManagerUrl: process.env.SLURRY_TWITTER_MANAGER_URL
      staticSchemasPath: process.env.SLURRY_TWITTER_STATIC_SCHEMAS_PATH
    }

  run: =>
    server = new Slurry @getOptions()
    @slurrySpreader.start (error) =>
      throw error if error?
      server.run (error) =>
        throw error if error?

        {address,port} = server.address()
        console.log "Server listening on #{address}:#{port}"

command = new Command()
command.run()
