FROM node:6.9.1

WORKDIR /web
COPY . .

RUN npm install -g yarn@0.27.5
RUN yarn install

CMD [ "yarn", "run", "serve" ]