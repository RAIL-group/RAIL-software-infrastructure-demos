import argparse
import random
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--seed', type=int, required=True)
    args = parser.parse_args()

    print(f"Seed {args.seed}: Starting")
    random.seed(args.seed)
    sleep_time = 1 + 1 * random.random()
    time.sleep(sleep_time)
    print(f"Seed {args.seed}: Ending")


if __name__ == "__main__":
    main()
