using Pkg.Artifacts
using Pkg.TOML

THEME_DIR = joinpath(@__DIR__, "themes")
BUILD_DIR = joinpath(@__DIR__, "build")
ARTIFACT_TOML = joinpath(@__DIR__, "Artifacts.toml")
URL = "https://github.com/MichaelHatherly/PublishThemes/releases/download"

function build(which...; themes = THEME_DIR, build = BUILD_DIR, artifact_toml = ARTIFACT_TOML, url = URL)
    # Clean up prior builds.
    ispath(build) && rm(build; recursive=true, force=true)
    mkdir(build)
    # Package up themes.
    for theme in readdir(themes)
        if isempty(which) || theme ∈ which
            path = joinpath(themes, theme)
            if isdir(path)
                meta = TOML.parsefile(joinpath(path, "Theme.toml"))
                theme′, version = meta["theme"], meta["version"]
                @assert theme == theme′
                product_hash = create_artifact() do artifact_dir
                    cp(path, artifact_dir; force=true)
                end
                archive_filename = "$theme-$version.tar.gz"
                download_hash = archive_artifact(product_hash, joinpath(build, archive_filename))
                remote_url = "$url/$theme-$version/$archive_filename"
                @info "Creating:" theme version product_hash archive_filename download_hash remote_url

                bind_artifact!(
                    artifact_toml,
                    "publish_theme_$theme",
                    product_hash,
                    force=true,
                    download_info=Tuple[(remote_url, download_hash)]
                )
            end
        end
    end
end