import argparse
import matplotlib.pyplot as plt
from unitybridge import UnityBridge
import time


def depths_from_depth_image(depth_image, max_range=200.0):
    """Helper function to convert output from depth camera
    to a measurement of depth."""
    return (1.0 * depth_image[:, :, 0] + depth_image[:, :, 1] / 256.0 +
            depth_image[:, :, 2] / 256.0 / 256.0) / 256.0 * max_range


def main():
    # Get the command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--unity_exe_path', type=str, required=True)
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
    with UnityBridge(args.unity_exe_path) as unity_bridge:
        start_time = time.time()
        pano_image = unity_bridge.get_image("agent/t_pano_camera")
        print(f"Time to get first image: {time.time() - start_time}")
        pano_seg_image = unity_bridge.get_image(
            "agent/t_pano_segmentation_camera")
        pano_depth_image = unity_bridge.get_image("agent/t_pano_depth_camera")
        pano_depth_image = depths_from_depth_image(pano_depth_image)

        # Plotting
        plt.figure(dpi=300, figsize=(6, 9))
        plt.subplot(3, 2, 1)
        plt.imshow(pano_image)
        plt.subplot(3, 2, 3)
        plt.imshow(pano_seg_image)
        plt.subplot(3, 2, 5)
        plt.imshow(pano_depth_image, vmin=0.0, vmax=12.0)

        # Now move and get more images
        unity_bridge.send_message("agent move 2.0 0.77 0.0 0")
        pano_image = unity_bridge.get_image("agent/t_pano_camera")
        start_time = time.time()
        pano_image = unity_bridge.get_image("agent/t_pano_camera")
        print(f"Time to get second image: {time.time() - start_time}")
        pano_seg_image = unity_bridge.get_image(
            "agent/t_pano_segmentation_camera")
        pano_depth_image = unity_bridge.get_image("agent/t_pano_depth_camera")
        pano_depth_image = depths_from_depth_image(pano_depth_image)

        # Plotting
        plt.subplot(3, 2, 2)
        plt.imshow(pano_image)
        plt.subplot(3, 2, 4)
        plt.imshow(pano_seg_image)
        plt.subplot(3, 2, 6)
        plt.imshow(pano_depth_image, vmin=0.0, vmax=12.0)

        # Show the plot or write it to file
        if args.xpassthrough == 'true':
            plt.show()
        elif args.output_image is not None:
            plt.savefig(args.output_image)


if __name__ == "__main__":
    main()
