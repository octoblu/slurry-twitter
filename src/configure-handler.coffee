fs   = require 'fs'
http = require 'http'
_    = require 'lodash'
path = require 'path'

NOT_FOUND_RESPONSE = {metadata: {code: 404, status: http.STATUS_CODES[404]}}

class ConfigureHandler
  constructor: ({ @slurrySpreader }={}) ->
    @configurations = @_getConfigurations()
    @_slurries = {}
    @slurrySpreader.on 'create', @_onSlurryCreate
    @slurrySpreader.on 'destroy', @_onSlurryDestroy

  onConfigure: ({auth, userDeviceUuid, encrypted, config}, callback) =>
    selectedConfiguration = config.schemas?.selected?.configure
    slurry = {
      auth
      selectedConfiguration
      encrypted
      config
      uuid: userDeviceUuid
    }
    return @slurrySpreader.remove(slurry, callback) if config.slurry?.disabled
    @slurrySpreader.add slurry, callback

  _onSlurryCreate: (slurry) =>
    {
      uuid
      selectedConfiguration
      config
      encrypted
      auth
    } = slurry
    slurryStream = @configurations[selectedConfiguration]
    return unless slurryStream?

    @_slurries[uuid]?.destroy()
    slurryStream.action {encrypted, auth, userDeviceUuid: uuid}, config, (error, slurryStream) =>
      return console.error error.stack if error?
      @_slurries[uuid] = slurryStream

  _onSlurryDestroy: (slurry) =>
    {
      uuid
    } = slurry
    @_slurries[uuid]?.destroy()

  formSchema: (callback) =>
    callback null, @_formSchemaFromConfigurations @configurations

  configureSchema: (callback) =>
    callback null, @_configureSchemaFromConfigurations @configurations

  _formSchemaFromConfigurations: (configurations) =>
    return {
      configure: _.mapValues configurations, 'form'
    }

  _getConfigurations: =>
    dirnames = fs.readdirSync path.join(__dirname, './configurations')
    configurations = {}
    _.each dirnames, (dirname) =>
      key = _.upperFirst _.camelCase dirname
      dir = path.join 'configurations', dirname
      configurations[key] = require "./#{dir}"
    return configurations

  _configureSchemaFromJob: (job, key) =>
    configure = _.cloneDeep job.configure
    _.set configure, 'x-form-schema.angular', "configure.#{key}.angular"
    configure.required = _.union ['metadata'], configure.required
    return configure

  _configureSchemaFromConfigurations: (configurations) =>
    _.mapValues configurations, @_configureSchemaFromJob

module.exports = ConfigureHandler
