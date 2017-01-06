# acbuild-debootstrap

This program builds a minimal Debian container using
[debootstrap](https://wiki.debian.org/Debootstrap).  The resulting
container is an [ACI](https://github.com/appc/spec) file following the
[App Container (appc) specification](https://github.com/appc/spec).
The container is built using
[acbuild](https://github.com/containers/build).

## Usage

Run with:

    $ ./acbuild-debootstrap.sh [-h]
         -n <pkg_name>
        [-d <workdir>]
        [-m <mode>]
        [-o <output_img>]

`pkg_name` is the name of the container and will be included in the
container metadata.  This parameter is required.

`workdir` is the path to a directory where a `tmpfs` will be mounted
and in which the container will be built.  By default, a directory
`tmp` is created in the same directory as the script itself.

`mode` can be one of:

- `init` - Create and mount the working directories
- `clean` - Unmount and cleanup the working directories
- `bootstrap` - Run debootstrap and prepare the Debian image
- `build` - Finalize the image before assembling the container
- `assemble` - Create the final ACI file

`output_img` is the filename to use for writing the final ACI
container image.  By default, this is `<pkg_name>.aci`.

## Installation

This program is a shell script that is designed to run under a minimal
shell such as `dash`.

### Dependencies

To use this program, you first need install:

- `debootstrap`
- `acbuild`

e.g.:

    apt-get install debootstrap acbuild

## License

This project is licensed under the
[MIT/Expat](https://opensource.org/licenses/MIT) license as found in
the [LICENSE](./LICENSE) file.
