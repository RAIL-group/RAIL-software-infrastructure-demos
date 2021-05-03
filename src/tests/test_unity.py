import pytest
from unitybridge import UnityBridge


@pytest.fixture()
def unity_exe_path(pytestconfig):
    return pytestconfig.getoption("unity_exe_path")


@pytest.mark.timeout(150)
def test_unity_generates_images(unity_exe_path):
    """Run Unity and generate a couple of images."""
    if unity_exe_path is None:
        pytest.xfail("Missing Unity environment exe path. "
                     "Set via '--unity_exe_path'.")

    # Open the unity environment and generate a few images
    with UnityBridge(unity_exe_path) as unity_bridge:
        pano_image = unity_bridge.get_image("agent/t_pano_camera")
        pano_seg_image = unity_bridge.get_image(
            "agent/t_pano_segmentation_camera")
        assert pano_image.max() > 0
        assert pano_seg_image.max() > 0

        # Move the agent and repeat
        unity_bridge.send_message("agent move 2.0 0.77 0.0 0")
        pano_image = unity_bridge.get_image("agent/t_pano_camera")
        pano_seg_image = unity_bridge.get_image(
            "agent/t_pano_segmentation_camera")
        assert pano_image.max() > 0
        assert pano_seg_image.max() > 0
