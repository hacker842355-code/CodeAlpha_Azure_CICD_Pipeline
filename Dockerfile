FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /usr/src/app
COPY package.json ./
COPY app ./app
USER node
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1
CMD ["node", "app/server.js"]
