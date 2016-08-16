fs   = require 'fs'
http = require 'http'
_    = require 'lodash'
path = require 'path'

NOT_FOUND_RESPONSE = {metadata: {code: 404, status: http.STATUS_CODES[404]}}

class ConfigureHandler
  constructor: ->
    @configurations = @_getConfigurations()

  onConfigure: ({auth, userDeviceUuid, encrypted, config}, callback) =>
    configuration = config.schemas?.selected?.configure
    job = @configurations[configuration]
    return callback null, NOT_FOUND_RESPONSE unless job?

    job.action {encrypted, auth, userDeviceUuid}, config, callback

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
