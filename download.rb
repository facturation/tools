#!/usr/bin/env ruby
#
# SCRIPT FOURNIT SANS AUCUNE GARANTIE D'AUCUNE SORTE DE LA PART DE FACTURATION.PRO
# FACTURATION.PRO NE POURRA ËTRE TENU POUR RESPONSABLE D'UN QUELCONQUE DYSFONCTIONNEMENT LIE A L'UTILISATION
# DE CE SCRIPT.
# CE SCRIPT VOUS PERMET UNIQUEMENT D'AVOIR UNE BASE POUR VOS DEVELOPPEMENTS SIMILAIRES
#
# A propos :
# Ce script permet de télécharger tous les devis et factures générés via notre outil, de manière incrémentale.
#
# Remarques :
# * les documents déjà téléchargés ne sont pas retéléchargés
# * les factures externes ne peuvent pas être générées par notre outil et donc ne sont pas téléchargeables
# * les brouillons ne sont jamais téléchargés
#
# Configuration :
# copier le fichier config.sample.yml, le remplir avec vos informations d'authentification,
# et enregistrer ce fichier sous le nom config.yml
#
# Usage :
# ruby ./download.rb
#

USER_AGENT = "BackupApp (support@facturation.pro)" # identifiez votre application avec votre adresse email

# install needed gems if missing
require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'rest-client'
end

require 'fileutils'
require 'yaml'

class Backup
  attr_accessor :max_pages, :config, :firm

  def initialize
    if File.exists?("./config.yml")
      self.config = YAML.load_file("./config.yml").each_with_object({}) { |(k,v), h| h[k.to_sym] = v }
    else
      $stderr.puts "Errror: config.yml is missing"
      exit
    end
  end

  def call
    return false unless config_ok?
    firms_list.each do |entry|
      self.firm = entry
      verify_directory
      download_all(:quotes)
      download_all(:invoices)
    end
    true
  end

  private

  def config_ok?
    unless config.is_a?(Hash)
      $stderr.puts "Invalid config file"
      return false
    end
    if config[:firm_id].to_i == 0 && (config[:firms].nil? || !config[:firms].is_a?(Array) || config[:firms].size == 0 )
      $stderr.puts "Missing firms list in config file"
      return false
    elsif config[:api_id].to_i == 0
      $stderr.puts "Missing api_id in config file"
      return false
    elsif config[:api_key].to_s.strip == ''
      $stderr.puts "Missing api_key in config file"
      return false
    elsif config[:directory].empty?
      $stderr.puts "Missing directory parameter in config file"
      return false
    end
    true
  end

  def base_path
    @base_path ||= {}
    @base_path[firm[:firm_id]] ||= File.join(File.expand_path(config[:directory]), firm[:subdirectory].to_s).to_s
    @base_path[firm[:firm_id]]
  end

  def base_url
    @base_url ||= {}
    @base_url[firm[:firm_id]] ||= begin
      host = config[:host] || "wwww.facturation.pro"
      protocol = config[:protocol] || "https"
      "#{protocol}://#{config[:api_id]}:#{config[:api_key]}@#{host}/firms/#{firm[:firm_id]}"
    end
    @base_url[firm[:firm_id]]
  end

  def firms_list
    if config[:firm_id].to_i>0
      [ { firm_id: config[:firm_id], subdirectory: nil } ]
    else
      config[:firms].collect do | entry |
        if entry[:firm_id].to_i == 0 || entry[:subdirectory].to_s == ''
          $stderr.puts "Invalid firm entry, you must provide both firm_id and subdirectory : #{entry.inspect}"
          exit
        else
          entry
        end
      end
    end
  end

  def verify_directory
    # check if DIRECTORY exists and create it if needed
    path = base_path
    FileUtils.mkdir_p(path)
    FileUtils.mkdir_p("#{path}/invoices/json")
    FileUtils.mkdir_p("#{path}/quotes/json")
    puts "--> Created #{path}"
  end

  def download_all(type)
    self.max_pages = 100
    page = 0
    while page < max_pages
      page += 1
      data = retrieve_bills(type, page)
      break if data.empty? # no more items
      data.each { |item| download_bill(type, item) }
    end
    puts "--> End #{type} download"
  end

  def retrieve_bills(type, page)
    puts "--> Firm #{firm[:firm_id]} - Retrieve #{type} list - page #{page}"
    url = "#{base_url}/#{type}.json?order=created&sort=desc&page=#{page}"
    puts url
    res = RestClient.get(url, { accept: :json, user_agent: USER_AGENT })
    if page == 1 && res.headers[:x_pagination]
      self.max_pages = JSON.parse(res.headers[:x_pagination])['total_pages']
    end
    JSON.parse(res.body)
  end

  def download_bill(type, item)
    filename = "#{item[id_key_for(type)]}.pdf"
    path = File.join(base_path, type.to_s, filename)
    if item['draft']
      # we don't retrieve draft
      puts "* Skipped #{item['id']} : draft"
      return false
    elsif item['external']
      puts "* Skipped #{filename} : external invoice"
      return false
    elsif File.exists?(path)
      puts "* Skipped #{filename} : already exists"
      return false
    end
    url = "#{base_url}/#{type}/#{item['id']}.pdf?original=1"
    raw = RestClient::Request.execute(
      method: :get,
      url: url,
      raw_response: true,
      headers: { user_agent: USER_AGENT }
    )
    puts "* Saved #{filename} : #{raw.file.size} bytes"
    FileUtils.mv(raw.file.path, path)
    sleep(1) # we dont want to hammer the API because of quota check
    true
  end


  def id_key_for(type)
    case type
    when :quote, :quotes then 'quote_ref'
    else 'full_invoice_ref'
    end
  end
end

Backup.new.call
