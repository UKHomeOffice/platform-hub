# Since the web app consists of static assets only, this docker image is
# intended to be a data only image that can be extended or mounted.
#
# This gives flexibility in how the app will be served, as the end user can
# choose whatever web server and mechanism they want.
#
# NOTE: this dockerfile expects that a built/optimized version of the web app is
# already available within `./dist`.

FROM alpine:3.12

COPY dist /app/
WORKDIR /app
