"use strict"

kraken = require 'kraken-js'
express = require 'express'
request = require 'supertest'
mocha = require 'mocha'
extend = require 'extend'

extend global, mocha