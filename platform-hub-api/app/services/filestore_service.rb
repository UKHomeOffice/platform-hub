class FilestoreService

  def initialize s3_region:, s3_bucket_name:, s3_access_key_id:, s3_secret_access_key:, s3_object_prefix: ''
    client = Aws::S3::Client.new({
      region: s3_region,
      access_key_id: s3_access_key_id,
      secret_access_key: s3_secret_access_key
    })
    @bucket = Aws::S3::Resource.new(client: client).bucket(s3_bucket_name)
    @object_prefix = s3_object_prefix
  end

  def names limit: 200
    opts = {
      max_keys: limit
    }

    if @object_prefix.present?
      opts[:prefix] = @object_prefix
    end

    @bucket
      .objects(opts)
      .sort_by { |o| o.last_modified }
      .reverse
      .map do |o|
        if @object_prefix.present?
          o.key.gsub(/\A#{@object_prefix}\//, '')
        else
          o.key
        end
      end
      .select(&:present?)
  end

  def get name
    key = generate_key name
    @bucket.object(key).get().body.read
  end

  private

  def generate_key name
    if @object_prefix.present?
      "#{@object_prefix}/#{name}"
    else
      name
    end
  end

end
