# Testing how sbt cache and docker cache works together

[SBT Dependency management](https://www.scala-sbt.org/1.x/docs/Library-Dependencies.html)
[Coursier cache](https://get-coursier.io/docs/cache)

## 1. No external mapping for sbt cache

1. Run ```docker build -t asstart.io.sbtbuildtest:0.1 .  --progress=plain``` - every layer has built
2. Run again ```docker build -t asstart.io.sbtbuildtest:0.1 .  --progress=plain``` - all layers cached
3. Change a line of code in the Main.scala
4. Run again ```docker build -t asstart.io.sbtbuildtest:0.1 .  --progress=plain``` - every layer starts from ```COPY src /app/src```
has built
5. Run again ```docker build -t asstart.io.sbtbuildtest:0.1 .  --progress=plain``` - all layers cached

## 2. Using RUN --mount=type=cache to prevent downloading dependencies every build

[Run --mount](https://docs.docker.com/engine/reference/builder/#run---mount)
[BuildKit builder must be turned on](https://docs.docker.com/build/buildkit/)

> -mount=type=cache,target=<path> must be mentioned in every RUN directive where cache is supposed to be used

> sbt 1.3.0+ uses Coursier to implement dependency management.
> Until sbt 1.3.0, sbt has used Apache Ivy for ten years.
> Coursier does a good job of keeping the compatibility, but some of the feature might be specific to Apache Ivy.
> In those cases, you can use the following setting to switch back to Ivy: ```ThisBuild / useCoursier := false```
> https://www.scala-sbt.org/1.x/docs/Library-Management.html#Automatic+Dependency+Management

> To override it, use the -Dsbt.coursier.home system property or the COURSIER_CACHE environment variable.
> https://get-coursier.io/docs/cache#sbt

> Doesn't work for some reason with path in env variable like in Dockerfile_cache_with_env

1. Run ```docker build -t asstart.io.sbtbuildtest-cached:0.1 .  --progress=plain -f Dockerfile_cache``` - every layer has built 

Operation | Size
--- | ---
Cache size before ```sbt build assembly``` | 4.0 K
Cache size after ```sbt build assembly``` | 167 M

2. Run again ```docker build -t asstart.io.sbtbuildtest-cached:0.1 .  --progress=plain -f Dockerfile_cache``` - all layers cached
3. Make changes in Main.scala
4. Run again ```docker build -t asstart.io.sbtbuildtest-cached:0.1 .  --progress=plain -f Dockerfile_cache``` - every layer starts from ```COPY src /app/src```
   has built but sbt dependencies were cached

Operation | Size MB
--- | ---
Cache size before ```sbt build assembly``` | 167 M
Cache size after ```sbt build assembly``` | 167 M

5. Run again ```docker build -t asstart.io.sbtbuildtest-cached:0.1 .  --progress=plain -f Dockerfile_cache``` - all layers cached
6. Make changes in Main.scala
7. Change version of any dependencies in build.sbt
8. Run again ```docker build -t asstart.io.sbtbuildtest-cached:0.1 .  --progress=plain -f Dockerfile_cache``` - every layer starts from ```COPY src /app/src```
   has built, new dependencies have downloaded

Operation | Size MB
--- | ---
Cache size before ```sbt build assembly``` | 167 M
Cache size after ```sbt build assembly``` | 210 M

9. Make changes in Main.scala
10. Run again ```docker build -t asstart.io.sbtbuildtest-cached:0.1 .  --progress=plain -f Dockerfile_cache``` - every layer starts from ```COPY src /app/src```
       has built, sbt dependencies cached

Operation | Size MB
--- | ---
Cache size before ```sbt build assembly``` | 210 M
Cache size after ```sbt build assembly``` | 210 M

11. Return versions of sbt dependencies to the previous
12. Run again ```docker build -t asstart.io.sbtbuildtest-cached:0.1 .  --progress=plain -f Dockerfile_cache``` - every layer starts from ```COPY src /app/src```
    has built, sbt dependencies cached

Operation | Size MB
--- | ---
Cache size before ```sbt build assembly``` | 210 M
Cache size after ```sbt build assembly``` | 210 M

## 3. Using --cache-from <img>

> Doc https://docs.docker.com/engine/reference/commandline/build/#specifying-external-cache-sources 

TODO