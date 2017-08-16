#####################################################################
##Bdd test in docker image.                                        ##
##build.sh is script for build Dockerfile                          ##
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
