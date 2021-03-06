#! /usr/bin/env ruby
#
#   check-checksums
#
# DESCRIPTION:
#   Check the file against its checksum
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux, BSD
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   AJ Bourg <aj@ajbourg.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'digest'

class Checksum < Sensu::Plugin::Check::CLI
  option :files,
         description: 'Comma separated list of files to check.',
         short: '-f FILES',
         long: '--files FILES',
         required: true

  option :hash,
         description: 'The hash these files must hash as. If unspecified the files will be compared to the first file.',
         short: '-h SHA2HASH',
         long: '--hash SHA2HASH'

  option :hashfile,
         description: 'The file containing the hash these files must hash as.',
         # i.e. sha256sum filename | awk '{print $1}' > filename.sha256sum
         short: '-H SHA2HASHFILE',
         long: '--hashfile SHA2HASHFILE'

  option :warn_only,
         description: "Warn instead of critical if they don't match",
         short: '-w',
         long: '--warn-only',
         boolean: true

  def run
    files = config[:files].split(',')

    if files.length == 1 && !config[:hash] && !config[:hashfile]
      unknown 'We have nothing to compare this file with.'
    end

    if config[:hashfile]
      hash = IO.read(config[:hashfile]).chomp
    else
      hash = config[:hash] || Digest::SHA2.file(files.first).hexdigest
    end

    errors = []

    files.each do |file|
      if File.exist?(file)
        file_hash = Digest::SHA2.file(file).hexdigest.chomp
        errors << "#{file} does not match" if file_hash != hash
      else
        errors << "#{file} does not exist"
      end
    end

    if errors.length > 0 && config[:warn_only]
      warning errors.join("\n")
    elsif errors.length > 0
      critical errors.join("\n")
    else
      ok 'Files match.'
    end
  end
end
