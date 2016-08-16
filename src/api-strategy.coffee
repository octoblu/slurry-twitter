_ = require 'lodash'
PassportTwitter = require 'passport-twitter'

class TwitterStrategy extends PassportTwitter
  constructor: (env) ->
    throw new Error('Missing required environment variable: SLURRY_TWITTER_TWITTER_CLIENT_ID')     if _.isEmpty process.env.SLURRY_TWITTER_TWITTER_CLIENT_ID
    throw new Error('Missing required environment variable: SLURRY_TWITTER_TWITTER_CLIENT_SECRET') if _.isEmpty process.env.SLURRY_TWITTER_TWITTER_CLIENT_SECRET
    throw new Error('Missing required environment variable: SLURRY_TWITTER_TWITTER_CALLBACK_URL')  if _.isEmpty process.env.SLURRY_TWITTER_TWITTER_CALLBACK_URL

    options = {
      consumerKey:    process.env.SLURRY_TWITTER_TWITTER_CLIENT_ID
      consumerSecret: process.env.SLURRY_TWITTER_TWITTER_CLIENT_SECRET
      callbackUrl:    process.env.SLURRY_TWITTER_TWITTER_CALLBACK_URL
    }

    super options, @onAuthorization

  onAuthorization: (token, tokenSecret, profile, callback) =>
    callback null, {
      id: profile.id
      username: profile.username
      secrets:
        credentials:
          token: token
          secret: tokenSecret
    }

module.exports = TwitterStrategy
