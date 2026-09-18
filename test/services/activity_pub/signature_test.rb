require "test_helper"

module ActivityPub
  class SignatureTest < ActiveSupport::TestCase
    include ActivityPubTestHelper

    setup do
      @body = { type: "Follow" }.to_json
      @headers = Signature.sign(method: :post, url: "https://example.com/activitypub/inbox", key: REMOTE_KEY, key_id: REMOTE_KEY_ID, body: @body)
    end

    def verifier(headers: @headers, body: @body, path: "/activitypub/inbox")
      Signature::Verifier.new(method: "POST", path: path, headers: headers.transform_keys(&:downcase), body: body)
    end

    test "sign produces host, date, digest and a signature over all of them" do
      assert_equal "example.com", @headers["Host"]
      assert_equal Signature.digest(@body), @headers["Digest"]
      assert_match(/keyId="#{Regexp.escape(REMOTE_KEY_ID)}"/, @headers["Signature"])
      assert_match(/headers="\(request-target\) host date digest"/, @headers["Signature"])
    end

    test "includes a non-default port in the host header" do
      headers = Signature.sign(method: :get, url: "http://localhost:3000/x", key: REMOTE_KEY, key_id: "k")
      assert_equal "localhost:3000", headers["Host"]
      assert_nil headers["Digest"]
    end

    test "verifies a correctly signed request" do
      assert_equal REMOTE_KEY_ID, verifier.key_id
      assert verifier.verify!(REMOTE_KEY.public_to_pem)
    end

    test "rejects a tampered body" do
      error = assert_raises(Signature::VerificationError) { verifier(body: { type: "Delete" }.to_json).verify!(REMOTE_KEY.public_to_pem) }
      assert_match(/Digest/, error.message)
    end

    test "rejects a different request path" do
      assert_raises(Signature::VerificationError) { verifier(path: "/elsewhere").verify!(REMOTE_KEY.public_to_pem) }
    end

    test "rejects a signature made with a different key" do
      other = OpenSSL::PKey::RSA.new(2048)
      assert_raises(Signature::VerificationError) { verifier.verify!(other.public_to_pem) }
    end

    test "rejects a stale date" do
      headers = Signature.sign(method: :post, url: "https://example.com/activitypub/inbox", key: REMOTE_KEY, key_id: REMOTE_KEY_ID, body: @body, date: 2.days.ago)
      error = assert_raises(Signature::VerificationError) { verifier(headers: headers).verify!(REMOTE_KEY.public_to_pem) }
      assert_match(/window/, error.message)
    end

    test "rejects a signature that doesn't cover the digest" do
      headers = @headers.merge("Signature" => @headers["Signature"].sub(" digest", ""))
      error = assert_raises(Signature::VerificationError) { verifier(headers: headers).verify!(REMOTE_KEY.public_to_pem) }
      assert_match(/digest/, error.message)
    end

    test "rejects an unsigned request" do
      assert_raises(Signature::VerificationError) { verifier(headers: @headers.except("Signature")) }
    end

    test "rejects an invalid public key" do
      assert_raises(Signature::VerificationError) { verifier.verify!("not a key") }
    end
  end
end
