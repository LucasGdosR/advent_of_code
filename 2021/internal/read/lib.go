package read

import "os"

func FileToBytes(path string) []byte {
	data, err := os.ReadFile(path)
	if err != nil {
		panic("failed to read file " + path + ": " + err.Error())
	}
	return data
}

func FileToString(path string) string {
	return string(FileToBytes(path))
}
