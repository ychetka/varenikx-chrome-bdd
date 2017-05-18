
##Bdd test in docker image.
With this you must run bdd test in docker image (in chrome)


You project must be use:
- nodeJs, npm (yarn)
- selenium as node modules
- nightwatch as node modules and nightwatch-cucumber as node modules

You project must be have:
- package.json in root project directory


# How to run
in docker:
docker run -v /path/to/you/project/:/project varenikx/chrome-bdd

in wercker box:

box:
  id: varenikx/chrome-bdd:latest
  entrypoint: /bin/bash -c
build:
  steps:
    - script:
        name: Run bdd
        code: |
          /entrypoint.sh
    - script:
        name: npm log
        code: |
          cat $HOME/npm.log
    - script:
        name: Yarn log
        code: |
          cat $HOME/yarn.log
    - script:
        name: Webpack log
        code: |
          cat $HOME/webpack.log

After all, script will be call to yarn test:spec in project dicrectory.
May be in future i do the 'yarn test:spec' as argument for docker run
