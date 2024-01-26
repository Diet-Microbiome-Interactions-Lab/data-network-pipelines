import glob

donor_key = {
    'DonorA': list(range(0, 22)),
    'DonorB': list(range(22, 43)),
    'DonorC': list(range(43, 64)),
    'DonorD': list(range(64, 85)),
    'DonorE': list(range(85, 106)),
    'DonorF': list(range(106, 127)),
}


def main(donor):
    with open(f'Abundance_List-{donor}.txt', 'w') as out:
        for file in glob.glob("*abundance.txt"):
            if donor in file:
                number = int(file.split('-')[1].split('_')[1])
                if number in donor_key[donor]:
                    out.write(f"Abundances/{file}\n")

    return 0


if __name__ == "__main__":
    import sys
    main(sys.argv[1])