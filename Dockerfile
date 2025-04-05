#Stage1: Base Node image with alpine for a small size
#Define node and alpine version
FROM node:23-alpine3.20 AS base
#Set work directory
WORKDIR /app
#install libc6-compat because it's required for nextjs apps on Alpine
RUN apk add --no-cache libc6-compat


#Stage2: Install production dependencies
FROM base AS dependencies
#Set work directory
WORKDIR /app

#Copy package and package-lock to install dependencies
COPY package.json .
COPY package-lock.json .
#install production dependencies only
RUN  npm i

#Stage3: Build the application
FROM base AS builder
#Set work directory
WORKDIR /app
#Copy node_modules from the previouse stage
COPY --from=dependencies /app/node_modules ./node_modules
#Copy package.json and the source code
COPY package.json .
#This copies everything
COPY . .
#Set env variables below later on

#Build the application
RUN npm run build

#Stage4: Create final runtime image using the standalone output
FROM base AS runner
#Set work directory
WORKDIR /app
#Set ENV to production
ENV NODE_ENV production
#Create a non-root user for security
RUN addgroup --system nextjs && adduser --system --ingroup nextjs nextjs
USER nextjs:nextjs
#Copy the required files from the build stage
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
#Expose the port the application is running on
EXPOSE 3000
#Command to run the standalone client
CMD ["node", "server.js"]