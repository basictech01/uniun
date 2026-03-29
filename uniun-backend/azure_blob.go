package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"strings"

	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
	"github.com/fiatjaf/khatru/blossom"
)

func initAzureBlossom(bl *blossom.BlossomServer) error {
	accountName := config.AzStorageAccountName
	accountKey := config.AzStorageAccountKey
	containerName := config.AzBlossomContainer

	if accountName == "" || accountKey == "" {
		return fmt.Errorf("azure storage account name or key is empty")
	}

	credential, err := azblob.NewSharedKeyCredential(accountName, accountKey)
	if err != nil {
		return fmt.Errorf("invalid azure credentials: %w", err)
	}

	serviceURL := fmt.Sprintf("https://%s.blob.core.windows.net/", accountName)
	client, err := azblob.NewClientWithSharedKeyCredential(serviceURL, credential, nil)
	if err != nil {
		return fmt.Errorf("failed to create azure client: %w", err)
	}

	Info("Initialized Azure Blossom storage", "container", containerName)

	bl.StoreBlob = append(bl.StoreBlob, func(ctx context.Context, sha256 string, ext string, body []byte) error {
		blobName := blobFilename(sha256, ext)
		_, err := client.UploadBuffer(ctx, containerName, blobName, body, nil)
		if err != nil {
			return fmt.Errorf("azure blob upload failed for %s: %w", blobName, err)
		}
		return nil
	})

	bl.LoadBlob = append(bl.LoadBlob, func(ctx context.Context, sha256 string, ext string) (io.ReadSeeker, error) {
		blobName := blobFilename(sha256, ext)
		resp, err := client.DownloadStream(ctx, containerName, blobName, nil)
		if err != nil {
			return nil, fmt.Errorf("azure blob download failed for %s: %w", blobName, err)
		}
		data, err := io.ReadAll(resp.Body)
		if err != nil {
			return nil, fmt.Errorf("azure blob read body failed for %s: %w", blobName, err)
		}
		return bytes.NewReader(data), nil
	})

	bl.DeleteBlob = append(bl.DeleteBlob, func(ctx context.Context, sha256 string, ext string) error {
		blobName := blobFilename(sha256, ext)
		_, err := client.DeleteBlob(ctx, containerName, blobName, nil)
		if err != nil {
			return fmt.Errorf("azure blob delete failed for %s: %w", blobName, err)
		}
		return nil
	})

	return nil
}

func blobFilename(sha256 string, ext string) string {
	cleanExt := strings.TrimPrefix(ext, ".")
	if cleanExt == "" {
		return sha256
	}
	return sha256 + "." + cleanExt
}
