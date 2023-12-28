#!/usr/bin/env sh

if [ ! -d "/src/output" ];
then
    echo "There is no volume mounted on /src/output"
    exit 1
fi

# Customize iPXE Build Configuration
# - Enable HTTPS protocol, default: TFTP, HTTP
cp /src/ipxe/src/config/general.h /src/ipxe/src/config/general.h.original
cat /src/ipxe/src/config/general.h.original | sed 's/#undef DOWNLOAD_PROTO_HTTPS/#define    DOWNLOAD_PROTO_HTTPS/' > /src/ipxe/src/config/general.h

# Inject embedded script
cp /src/embedded-script.ipxe /src/ipxe/src/script.ipxe

# Build BIOS image
cd /src/ipxe/src
make bin/undionly.kpxe EMBED=script.ipxe || exit 1

# Copy generated artifacts
cp script.ipxe /src/output/undionly-embedded.ipxe
cp bin/undionly.kpxe /src/output/undionly.kpxe
exit 0