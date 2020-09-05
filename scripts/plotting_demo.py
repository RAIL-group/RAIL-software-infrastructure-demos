"""Simple script to plot random data and optionally write to file."""
import argparse
import matplotlib.pyplot as plt
import numpy as np


def main():
    # Get the command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--output_image',
                        type=str,
                        required=False,
                        default=None)
    parser.add_argument('--xpassthrough',
                        type=str,
                        required=False,
                        default='false')
    args = parser.parse_args()

    # Open the unity environment and generate a few images
    rand_data = np.random.random((10, 10))
    # Plotting
    plt.figure(dpi=300, figsize=(5, 5))
    plt.imshow(rand_data)

    # Show the plot or write it to file
    if args.xpassthrough == 'true':
        plt.show()
    elif args.output_image is not None:
        plt.savefig(args.output_image)
    else:
        raise ValueError(
            "Need either --output_image to be set "
            "or --xpassthrough=='true'"
        )


if __name__ == "__main__":
    main()
