##Dockerhub URL to sha https://hub.docker.com/layers/uphold/litecoin-core/0.18.1/images/sha256-fb3148b0ca9fb3075ea7670c1690d4fa8bcf323d72a4c7192d8da235d95ee994?context=explore
ARG LIGHTCOIN_DIGEST=sha256:fb3148b0ca9fb3075ea7670c1690d4fa8bcf323d72a4c7192d8da235d95ee994

FROM uphold/litecoin-core@${LIGHTCOIN_DIGEST} as lightcoin
