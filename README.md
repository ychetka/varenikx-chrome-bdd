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
or
docker -e GIT='{"repository":"...","token":"...","pullRequestId":"...","branch":"...' -e RUN='yarn run test:spec' varenikx/chrome-bdd:latest


