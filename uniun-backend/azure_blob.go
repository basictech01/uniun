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

	Debug("Initializing Azure Blossom storage", "container", containerName)

	// Validate config
	if accountName == "" || accountKey == "" {
		Error("Azure storage account configuration is invalid", "container", containerName)
		return fmt.Errorf("azure storage account name or key is empty")
	}
	if containerName == "" {
		Error("Azure blossom container configuration is invalid")
		return fmt.Errorf("azure container name is empty")
	}

	// Create credentials
	credential, err := azblob.NewSharedKeyCredential(accountName, accountKey)
	if err != nil {
		Error("Failed to create Azure shared key credentials", "container", containerName, "err", err)
		return fmt.Errorf("invalid azure credentials: %w", err)
	}

	// Create client
	serviceURL := fmt.Sprintf("https://%s.blob.core.windows.net/", accountName)
	client, err := azblob.NewClientWithSharedKeyCredential(serviceURL, credential, nil)
	if err != nil {
		Error("Failed to create Azure blob client", "container", containerName, "err", err)
		return fmt.Errorf("failed to create azure client: %w", err)
	}

	// Ensure container exists
	ctx := context.Background()
	containerClient := client.ServiceClient().NewContainerClient(containerName)

	_, err = containerClient.Create(ctx, nil)
	if err != nil && !strings.Contains(err.Error(), "ContainerAlreadyExists") {
		Error("Failed to create Azure container", "container", containerName, "err", err)
		return fmt.Errorf("failed to create container: %w", err)
	}
	if err != nil {
		Debug("Azure container already exists", "container", containerName)
	} else {
		Info("Created Azure container for Blossom storage", "container", containerName)
	}

	Info("Initialized Azure Blossom storage", "container", containerName)

	// Upload (Store)
	bl.StoreBlob = append(bl.StoreBlob, func(ctx context.Context, sha256 string, ext string, body []byte) error {
		blobName := blobFilename(sha256, ext)
		Debug("Uploading blob to Azure", "container", containerName, "blob", blobName, "sha256", sha256, "ext", ext, "size_bytes", len(body))

		_, err := client.UploadBuffer(ctx, containerName, blobName, body, nil)
		if err != nil {
			Error("Azure blob upload failed", "container", containerName, "blob", blobName, "sha256", sha256, "ext", ext, "err", err)
			return fmt.Errorf("azure blob upload failed for %s: %w", blobName, err)
		}
		Debug("Azure blob upload succeeded", "container", containerName, "blob", blobName, "sha256", sha256, "ext", ext, "size_bytes", len(body))

		return nil
	})

	// Download (Load)
	bl.LoadBlob = append(bl.LoadBlob, func(ctx context.Context, sha256 string, ext string) (io.ReadSeeker, error) {
		blobName := blobFilename(sha256, ext)
		Debug("Downloading blob from Azure", "container", containerName, "blob", blobName, "sha256", sha256, "ext", ext)

		resp, err := client.DownloadStream(ctx, containerName, blobName, nil)
		if err != nil {
			Error("Azure blob download failed", "container", containerName, "blob", blobName, "sha256", sha256, "ext", ext, "err", err)
			return nil, fmt.Errorf("azure blob download failed for %s: %w", blobName, err)
		}
		defer resp.Body.Close()

		data, err := io.ReadAll(resp.Body)
		if err != nil {
			Error("Failed to read Azure blob response body", "container", containerName, "blob", blobName, "sha256", sha256, "ext", ext, "err", err)
			return nil, fmt.Errorf("azure blob read body failed for %s: %w", blobName, err)
		}
		Debug("Azure blob download succeeded", "container", containerName, "blob", blobName, "sha256", sha256, "ext", ext, "size_bytes", len(data))

		return bytes.NewReader(data), nil
	})

	// Delete
	bl.DeleteBlob = append(bl.DeleteBlob, func(ctx context.Context, sha256 string, ext string) error {
		blobName := blobFilename(sha256, ext)
		Debug("Deleting blob from Azure", "container", containerName, "blob", blobName, "sha256", sha256, "ext", ext)

		_, err := client.DeleteBlob(ctx, containerName, blobName, nil)
		if err != nil {
			Error("Azure blob delete failed", "container", containerName, "blob", blobName, "sha256", sha256, "ext", ext, "err", err)
			return fmt.Errorf("azure blob delete failed for %s: %w", blobName, err)
		}
		Debug("Azure blob delete succeeded", "container", containerName, "blob", blobName, "sha256", sha256, "ext", ext)

		return nil
	})

	return nil
}

// Blob naming helper
func blobFilename(sha256 string, ext string) string {
	cleanExt := strings.TrimPrefix(ext, ".")
	if cleanExt == "" {
		return sha256
	}
	return sha256 + "." + cleanExt
}
