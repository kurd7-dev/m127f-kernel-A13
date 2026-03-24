#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Auto-pack AnyKernel zip with auto-incrementing version
# Version logic:
#   no old zip   -> 1.0
#   1.0          -> 1.1
#   1.9          -> 2.0
# =========================================================

# ---------- Config ----------
OUT_DIR="${OUT_DIR:-out}"
RELEASES_DIR="${RELEASES_DIR:-releases}"
DEFAULT_AK_PATTERN="${DEFAULT_AK_PATTERN:-AnyKernel*}"

# Image candidates in priority order
IMAGE_CANDIDATES=(
  "${OUT_DIR}/arch/arm64/boot/Image"
    "${OUT_DIR}/arch/arm64/boot/Image.gz"
      "${OUT_DIR}/arch/arm64/boot/Image.lz4"
        "${OUT_DIR}/arch/arm64/boot/zImage"
        )

        # Optional extra files if present
        OPTIONAL_FILES=(
          "${OUT_DIR}/arch/arm64/boot/dtb"
            "${OUT_DIR}/arch/arm64/boot/dtb.img"
              "${OUT_DIR}/arch/arm64/boot/dtbo.img"
              )

              # ---------- Helpers ----------
              msg() { printf '\n[+] %s\n' "$*"; }
              err() { printf '\n[!] %s\n' "$*" >&2; exit 1; }

              find_anykernel_dir() {
                local found=""
                  local matches=()

                    while IFS= read -r -d '' dir; do
                        matches+=("$dir")
                          done < <(find . -maxdepth 2 -type d \( -name "AnyKernel*" -o -name "anykernel*" \) -print0)

                            if [[ ${#matches[@]} -eq 0 ]]; then
                                err "No AnyKernel folder found. Put AnyKernel in repo root, for example: ./AnyKernel3"
                                  fi

                                    if [[ ${#matches[@]} -eq 1 ]]; then
                                        printf '%s\n' "${matches[0]}"
                                            return
                                              fi

                                                # Prefer exact/common names first
                                                  for dir in "${matches[@]}"; do
                                                      case "$(basename "$dir")" in
                                                            AnyKernel3|AnyKernel|anykernel3|anykernel)
                                                                    printf '%s\n' "$dir"
                                                                            return
                                                                                    ;;
                                                                                        esac
                                                                                          done

                                                                                            # Otherwise choose the first one alphabetically
                                                                                              IFS=$'\n' found="$(printf '%s\n' "${matches[@]}" | sort | head -n1)"
                                                                                                printf '%s\n' "$found"
                                                                                                }

                                                                                                find_kernel_image() {
                                                                                                  local img
                                                                                                    for img in "${IMAGE_CANDIDATES[@]}"; do
                                                                                                        if [[ -f "$img" ]]; then
                                                                                                              printf '%s\n' "$img"
                                                                                                                    return
                                                                                                                        fi
                                                                                                                          done
                                                                                                                            err "No built kernel image found in ${OUT_DIR}/arch/arm64/boot/"
                                                                                                                            }

                                                                                                                            detect_device_name() {
                                                                                                                              local repo_name
                                                                                                                                repo_name="$(basename "$(pwd)")"
                                                                                                                                  repo_name="${repo_name// /-}"
                                                                                                                                    printf '%s\n' "$repo_name"
                                                                                                                                    }

                                                                                                                                    extract_version_from_name() {
                                                                                                                                      local name="$1"
                                                                                                                                        if [[ "$name" =~ ([0-9]+)\.([0-9]+) ]]; then
                                                                                                                                            printf '%s.%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
                                                                                                                                              fi
                                                                                                                                              }

                                                                                                                                              next_version() {
                                                                                                                                                local last="${1:-}"
                                                                                                                                                  local major minor

                                                                                                                                                    if [[ -z "$last" ]]; then
                                                                                                                                                        printf '1.0\n'
                                                                                                                                                            return
                                                                                                                                                              fi

                                                                                                                                                                major="${last%%.*}"
                                                                                                                                                                  minor="${last##*.}"

                                                                                                                                                                    if ! [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]]; then
                                                                                                                                                                        printf '1.0\n'
                                                                                                                                                                            return
                                                                                                                                                                              fi

                                                                                                                                                                                if (( minor < 9 )); then
                                                                                                                                                                                    minor=$((minor + 1))
                                                                                                                                                                                      else
                                                                                                                                                                                          major=$((major + 1))
                                                                                                                                                                                              minor=0
                                                                                                                                                                                                fi

                                                                                                                                                                                                  printf '%d.%d\n' "$major" "$minor"
                                                                                                                                                                                                  }

                                                                                                                                                                                                  find_latest_version() {
                                                                                                                                                                                                    local releases_dir="$1"
                                                                                                                                                                                                      local device="$2"
                                                                                                                                                                                                        local latest=""
                                                                                                                                                                                                          local versions=()
                                                                                                                                                                                                            local f base v

                                                                                                                                                                                                              mkdir -p "$releases_dir"

                                                                                                                                                                                                                shopt -s nullglob
                                                                                                                                                                                                                  for f in "$releases_dir"/*.zip; do
                                                                                                                                                                                                                      base="$(basename "$f")"
                                                                                                                                                                                                                          v="$(extract_version_from_name "$base" || true)"
                                                                                                                                                                                                                              if [[ -n "$v" ]]; then
                                                                                                                                                                                                                                    versions+=("$v")
                                                                                                                                                                                                                                        fi
                                                                                                                                                                                                                                          done
                                                                                                                                                                                                                                            shopt -u nullglob

                                                                                                                                                                                                                                              if [[ ${#versions[@]} -eq 0 ]]; then
                                                                                                                                                                                                                                                  printf '\n'
                                                                                                                                                                                                                                                      return
                                                                                                                                                                                                                                                        fi

                                                                                                                                                                                                                                                          latest="$(
                                                                                                                                                                                                                                                              printf '%s\n' "${versions[@]}" |
                                                                                                                                                                                                                                                                    sort -t. -k1,1n -k2,2n |
                                                                                                                                                                                                                                                                          tail -n1
                                                                                                                                                                                                                                                                            )"

                                                                                                                                                                                                                                                                              printf '%s\n' "$latest"
                                                                                                                                                                                                                                                                              }

                                                                                                                                                                                                                                                                              copy_kernel_files() {
                                                                                                                                                                                                                                                                                local ak_dir="$1"
                                                                                                                                                                                                                                                                                  local image="$2"
                                                                                                                                                                                                                                                                                    local base_image
                                                                                                                                                                                                                                                                                      base_image="$(basename "$image")"

                                                                                                                                                                                                                                                                                        msg "Copying kernel image: $base_image"
                                                                                                                                                                                                                                                                                          cp -f "$image" "$ak_dir/$base_image"

                                                                                                                                                                                                                                                                                            local f
                                                                                                                                                                                                                                                                                              for f in "${OPTIONAL_FILES[@]}"; do
                                                                                                                                                                                                                                                                                                  if [[ -f "$f" ]]; then
                                                                                                                                                                                                                                                                                                        msg "Copying optional file: $(basename "$f")"
                                                                                                                                                                                                                                                                                                              cp -f "$f" "$ak_dir/$(basename "$f")"
                                                                                                                                                                                                                                                                                                                  fi
                                                                                                                                                                                                                                                                                                                    done
                                                                                                                                                                                                                                                                                                                    }

                                                                                                                                                                                                                                                                                                                    pack_zip() {
                                                                                                                                                                                                                                                                                                                      local ak_dir="$1"
                                                                                                                                                                                                                                                                                                                        local zip_path="$2"

                                                                                                                                                                                                                                                                                                                          mkdir -p "$(dirname "$zip_path")"

                                                                                                                                                                                                                                                                                                                            (
                                                                                                                                                                                                                                                                                                                                cd "$ak_dir"

                                                                                                                                                                                                                                                                                                                                    # Remove junk if present
                                                                                                                                                                                                                                                                                                                                        rm -f ./*.zip

                                                                                                                                                                                                                                                                                                                                            zip -r9 "$OLDPWD/$zip_path" . \
                                                                                                                                                                                                                                                                                                                                                  -x '*.git*' \
                                                                                                                                                                                                                                                                                                                                                        -x 'README*' \
                                                                                                                                                                                                                                                                                                                                                              -x '*.md' \
                                                                                                                                                                                                                                                                                                                                                                    -x 'LICENSE*' \
                                                                                                                                                                                                                                                                                                                                                                          -x '.github/*' \
                                                                                                                                                                                                                                                                                                                                                                                -x '*.zip'
                                                                                                                                                                                                                                                                                                                                                                                  )
                                                                                                                                                                                                                                                                                                                                                                                  }

                                                                                                                                                                                                                                                                                                                                                                                  # ---------- Main ----------
                                                                                                                                                                                                                                                                                                                                                                                  AK_DIR="$(find_anykernel_dir)"
                                                                                                                                                                                                                                                                                                                                                                                  IMAGE_PATH="$(find_kernel_image)"
                                                                                                                                                                                                                                                                                                                                                                                  DEVICE_NAME="$(detect_device_name)"
                                                                                                                                                                                                                                                                                                                                                                                  LAST_VERSION="$(find_latest_version "$RELEASES_DIR" "$DEVICE_NAME")"
                                                                                                                                                                                                                                                                                                                                                                                  NEW_VERSION="$(next_version "$LAST_VERSION")"

                                                                                                                                                                                                                                                                                                                                                                                  ZIP_NAME="${DEVICE_NAME}-${NEW_VERSION}.zip"
                                                                                                                                                                                                                                                                                                                                                                                  ZIP_PATH="${RELEASES_DIR}/${ZIP_NAME}"

                                                                                                                                                                                                                                                                                                                                                                                  msg "AnyKernel folder : $AK_DIR"
                                                                                                                                                                                                                                                                                                                                                                                  msg "Kernel image     : $IMAGE_PATH"
                                                                                                                                                                                                                                                                                                                                                                                  msg "Last version     : ${LAST_VERSION:-none}"
                                                                                                                                                                                                                                                                                                                                                                                  msg "New version      : $NEW_VERSION"
                                                                                                                                                                                                                                                                                                                                                                                  msg "Output zip       : $ZIP_PATH"

                                                                                                                                                                                                                                                                                                                                                                                  copy_kernel_files "$AK_DIR" "$IMAGE_PATH"
                                                                                                                                                                                                                                                                                                                                                                                  pack_zip "$AK_DIR" "$ZIP_PATH"

                                                                                                                                                                                                                                                                                                                                                                                  msg "Done: $ZIP_PATH"