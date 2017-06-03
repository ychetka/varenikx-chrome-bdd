#####################################################################
##Bdd test in docker image.                                        ##
##With this you must run bdd test in docker image (in chrome)      ##
#####################################################################


You project must be use:
- nodeJs, npm (yarn)
- selenium as node modules
- nightwatch as node modules and nightwatch-cucumber as node modules

You project must be have:
- package.json in root project directory


# How to run

*in docker:
/*'yarn run test' - this command run you bdd tests.*/
docker pull varenikx/chrome-bdd:latest
docker run -v /path/to/you/project/:/project -e RUN='yarn run test:spec' varenikx/chrome-bdd:latest

*in wercker box:
box:
  id: varenikx/chrome-bdd:latest
  entrypoint: /bin/bash -c
  command-timeout: 40
build:
  steps:
    - script:
        name: Init headless system mode. Entrypoint.
        code: |
          /entrypoint.sh
    - script:
        name: Run bdd.
        code: |
          /*this run you test*/
          yarn run test
    - script:
        name: npm log
        code: |
          cat $HOME/npm.log
    - script:
        name: yarn log
        code: |
          cat $HOME/yarn.log
    - script:
        name: webpack log
        code: |
          cat $HOME/webpack.log

After all, script will be call to yarn test:spec in project dicrectory.

I think doog idea write part from nightwatch config (chrome in headless mode).

    "selenium": {
        ...
        "server_path": require('selenium-server-standalone-jar').path,
        "host": "127.0.0.1",
        "port": 4445
    },

    "test_settings": {
        "default": {
            ...
            "selenium_port": 4445,
            "selenium_host": "localhost",
            "desiredCapabilities": {
                ...
                "browserName": "chrome",
                "javascriptEnabled": true,
                "acceptSslCerts": true,
                "trustAllSSLCertificates": true,
                "chromeOptions" : {
                    "args" : [
                        "--disable-gpu",
                        "--start-maximized",
                        "--no-sandbox",
                        "--no-default-browser-check"
                    ]
                }
            }
        }
