FROM node:6.9.1

WORKDIR /app
COPY . .
RUN npm install -g yarn@0.27.5
RUN git config --global url."https://".insteadOf git://
RUN yarn install

CMD [ "yarn", "run", "serve" ]
