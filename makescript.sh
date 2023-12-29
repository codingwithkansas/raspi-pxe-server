RASPINIT_VERSION="main"
BUILD_DIR="build"
OUTPUT_FILENAME="raspipxe-0.1.0-ubuntu-22.04.3-arm64"
BASE_IMAGE_URL="https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-preinstalled-server-arm64+raspi.img.xz"

IPXE_DOCKER_BUILD_CTX_IMAGE="raspi-pxe-server--ipxe"

function clean {
    PROJECT_DIR="$1"
    rm -rf "$PROJECT_DIR/$BUILD_DIR"
    rm -rf "$PROJECT_DIR/ipxe/build"
    docker image rm -f "$(docker images -q $IPXE_DOCKER_BUILD_CTX_IMAGE)"
}

function initialize {
    PROJECT_DIR="$1"
    mkdir "$PROJECT_DIR/$BUILD_DIR"
    git clone --depth 1 -b "$RASPINIT_VERSION" "https://github.com/codingwithkansas/raspinit.git" "$PROJECT_DIR/$BUILD_DIR"
}

function build {
    PROJECT_DIR="$1"
    if [[ ! -d "$PROJECT_DIR/$BUILD_DIR" ]];
    then
        echo "You must run 'make init' first"
        exit 1
    fi

    if [[ ! -f "$PROJECT_DIR/templates/root-partition/tftpboot/undionly.kpxe" ]];
    then
        make build-ipxe
    fi

    rm -rf "$PROJECT_DIR/$BUILD_DIR/templates"
    cp -R "$PROJECT_DIR/templates" "$PROJECT_DIR/$BUILD_DIR/templates"
    mkdir "$PROJECT_DIR/$BUILD_DIR/templates/boot-partition"
    helm template -s templates/metadata.yaml -f "$PROJECT_DIR/config.yaml" "$PROJECT_DIR/helm-cloudinit-raspi-pxe" | tail -n +3 > "$PROJECT_DIR/$BUILD_DIR/templates/boot-partition/metadata"
    helm template -s templates/network-config.yaml -f "$PROJECT_DIR/config.yaml" "$PROJECT_DIR/helm-cloudinit-raspi-pxe" | tail -n +3 > "$PROJECT_DIR/$BUILD_DIR/templates/boot-partition/network-config"
    helm template -s templates/user-data.yaml -f "$PROJECT_DIR/config.yaml" "$PROJECT_DIR/helm-cloudinit-raspi-pxe" | tail -n +3 > "$PROJECT_DIR/$BUILD_DIR/templates/boot-partition/user-data"
    cd "$PROJECT_DIR/$BUILD_DIR"
    jq -n --arg output_filename "$OUTPUT_FILENAME" \
          --arg base_image_url "$BASE_IMAGE_URL" \
          '{output_filename: $output_filename, base_image_url: $base_image_url}' > "$PROJECT_DIR/$BUILD_DIR/config.json"
    make build
}

function build_ipxe {
    PROJECT_DIR="$1"
    IPXE_DIR="$PROJECT_DIR/ipxe"
    IPXE_BUILD_DIR="$IPXE_DIR/build"

    if [[ -z "$(docker images -q $IPXE_DOCKER_BUILD_CTX_IMAGE)" ]];
    then
        docker build -t "$IPXE_DOCKER_BUILD_CTX_IMAGE" "$IPXE_DIR"
    fi

    mkdir "$IPXE_BUILD_DIR"
    docker run --rm -it \
        -v "$PROJECT_DIR/templates/embedded-script.ipxe:/src/embedded-script.ipxe" \
        -v "$IPXE_BUILD_DIR:/src/output" \
        "$IPXE_DOCKER_BUILD_CTX_IMAGE"

    cp "$IPXE_BUILD_DIR/undionly.kpxe" "$PROJECT_DIR/templates/root-partition/tftpboot/undionly.kpxe"
    cp "$IPXE_BUILD_DIR/undionly-embedded.ipxe" "$PROJECT_DIR/templates/root-partition/tftpboot/undionly-embedded.ipxe"
}
