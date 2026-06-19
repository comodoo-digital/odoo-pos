do_configure() {
    python3 ${S}/build/gen.py \
        --platform=${@gn_platform("TARGET_OS", d)} \
        --out-path=${B} \
        --no-static-libstdc++ \
        --no-strip \
        --allow-warnings
}
