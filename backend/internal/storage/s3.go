package storage

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
)

// S3Config holds configuration needed to instantiate an S3-compatible client.
type S3Config struct {
	Endpoint  string
	Region    string
	Bucket    string
	AccessKey string
	SecretKey string
}

type s3Client struct {
	bucket  string
	baseURL string
	client  *s3.Client
	presign *s3.PresignClient
}

// NewS3Client creates an S3 compatible client (works with Cloudflare R2).
func NewS3Client(cfg S3Config) (Client, error) {
	if cfg.Bucket == "" {
		return nil, fmt.Errorf("%w: bucket", ErrIncompleteConfig)
	}
	if cfg.Region == "" {
		cfg.Region = "auto"
	}
	if cfg.Endpoint == "" {
		return nil, fmt.Errorf("%w: endpoint", ErrIncompleteConfig)
	}
	if cfg.AccessKey == "" || cfg.SecretKey == "" {
		return nil, fmt.Errorf("%w: credentials", ErrIncompleteConfig)
	}

	endpoint := strings.TrimSuffix(cfg.Endpoint, "/")

	awsCfg := aws.Config{
		Credentials: aws.NewCredentialsCache(credentials.NewStaticCredentialsProvider(cfg.AccessKey, cfg.SecretKey, "")),
		Region:      cfg.Region,
	}

	awsCfg.EndpointResolverWithOptions = aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
		if service == s3.ServiceID {
			return aws.Endpoint{
				PartitionID:       "aws",
				URL:               endpoint,
				SigningRegion:     cfg.Region,
				HostnameImmutable: true,
			}, nil
		}
		return aws.Endpoint{}, &aws.EndpointNotFoundError{}
	})

	client := s3.NewFromConfig(awsCfg, func(o *s3.Options) {
		o.UsePathStyle = true
	})
	presign := s3.NewPresignClient(client)

	return &s3Client{
		bucket:  cfg.Bucket,
		baseURL: endpoint,
		client:  client,
		presign: presign,
	}, nil
}

func (c *s3Client) PutObject(ctx context.Context, key string, body io.Reader, metadata map[string]string) (string, error) {
	input := &s3.PutObjectInput{
		Bucket: aws.String(c.bucket),
		Key:    aws.String(key),
		Body:   body,
	}

	if len(metadata) > 0 {
		md := make(map[string]string, len(metadata))
		for k, v := range metadata {
			md[k] = v
		}
		input.Metadata = md
	}

	if _, err := c.client.PutObject(ctx, input); err != nil {
		return "", err
	}

	return c.objectURL(key), nil
}

func (c *s3Client) PresignUpload(ctx context.Context, key string, ttl time.Duration, contentType string) (PresignedUpload, error) {
	input := &s3.PutObjectInput{
		Bucket:      aws.String(c.bucket),
		Key:         aws.String(key),
		ContentType: aws.String(contentType),
		ACL:         types.ObjectCannedACLPrivate,
	}

	request, err := c.presign.PresignPutObject(ctx, input, func(opts *s3.PresignOptions) {
		opts.Expires = ttl
	})
	if err != nil {
		return PresignedUpload{}, err
	}

	return PresignedUpload{
		URL:     request.URL,
		Method:  http.MethodPut,
		Headers: request.SignedHeader,
	}, nil
}

func (c *s3Client) objectURL(key string) string {
	return fmt.Sprintf("%s/%s/%s", strings.TrimSuffix(c.baseURL, "/"), c.bucket, strings.TrimPrefix(key, "/"))
}
