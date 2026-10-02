# --------------------------------------------------------------------------
# Stage 1: Build stage
# --------------------------------------------------------------------------
FROM dart:3.9.0-sdk AS build

# Set working directory
WORKDIR /app

# Copy pubspec files first for caching
COPY pubspec.* ./

# Get dependencies
RUN dart pub get

# Copy the rest of the source code
COPY . .

# Environment variables for non-interactive build (optional)
# Can be overridden at docker run/build time
ENV JL_PATH_FOLDER=build/
ENV JL_EXEC_NAME=builder
ENV JL_BUILD_EXCLUDE=""
ENV JL_BUILD_INCLUDE=""
ENV JL_BUILD_NO_INTERACT=true

# Run Jetleaf build
# Use --no-interact if JL_BUILD_NO_INTERACT is true
RUN if [ "$JL_BUILD_NO_INTERACT" = "true" ]; then \
  dart run jetleaf_cli:jl build --no-interact; \
else \
  dart run jetleaf_cli:jl build; \
fi

# --------------------------------------------------------------------------
# Stage 2: Runtime stage (smaller image)
# --------------------------------------------------------------------------
FROM dart:3.9.0-sdk AS runtime

# Set working directory
WORKDIR /app

# Copy compiled build artifacts from build stage
COPY --from=build /app/build ./build
COPY --from=build /app/pubspec.* ./

# Expose the default port (change if needed)
EXPOSE 8080

# Entrypoint: run the compiled Jetleaf builder
CMD ["dart", "run", "build/builder.dill"]
