# Use a multi-stage build for smaller final image
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy package files and install dependencies
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* tsconfig.json ./
COPY prisma ./prisma
COPY next.config.js .
RUN \
    if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile; \
    else echo "Lockfile not found." && exit 1; \
    fi

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/next.config.js .
COPY --from=deps /app/prisma ./prisma
COPY . .


# Set environment variables
ARG ENVIRONMENT=${ENVIRONMENT}
ENV ENVIRONMENT=${ENVIRONMENT}

# Build the application
RUN \
    if [ -f yarn.lock ]; then yarn run build; \
    elif [ -f package-lock.json ]; then npm run build; \
    elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm run build; \
    else echo "Lockfile not found." && exit 1; \
    fi

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV PORT 3000
ENV NODE_ENV production

COPY --from=builder /app/public ./public

# Set user and expose port
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
RUN mkdir .next && chown nextjs:nodejs .next
RUN mkdir .next/static

# Copy files and set permissions
COPY --from=builder --chown=nextjs:nodejs /app/next.config.js .
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone .
COPY --from=builder --chown=nextjs:nodejs /app/.next/static/. ./.next/static
COPY --from=builder /app/package.json .

USER nextjs
EXPOSE 3000

# Run the application
CMD node ./server.js
