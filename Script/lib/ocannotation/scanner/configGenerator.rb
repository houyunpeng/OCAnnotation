$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'annotation'
require 'globalConfig'
require 'fileutils'

module AFWAnnotation
	class ConfigGenerator
		ANNO_INFO_KEY_TYPE = "type"
		ANNO_INFO_KEY_POSITION = "position"
		ANNO_INFO_KEY_PARAMS = "params"
		ANNO_INFO_KEY_CLASS_NAME = "className"
		ANNO_INFO_KEY_SELECTOR = "selector"
		ANNO_INFO_KEY_PROPERTY_NAME = "propertyName"

		def initialize()
			@workspace = Dir.pwd
			@annotations = Array.new
			unless Dir.exist?('build')
				Dir.mkdir('build')
			end

			@config = AFWAnnotation::GlobalConfig.new
			@anno_infos_dic = GlobalConfig.load_file(@config.build_info_cache_path)
			if @anno_infos_dic.nil?
				@anno_infos_dic = Hash.new
			end

			@generate_file_path = @config.build_workspace_path + "/#{@config.generated_file_name_with_ext}"
		end

		def add_annotation(annotation)
			@annotations.push(annotation)
		end
		
		def generate_oc_header
			self.prepare_to_generate_file
			self.generate_cache_file

			File.open(@generate_file_path,"w") { |file|
				puts "\nstart generate...\n"
				file << "//this file is generated by OCAnnotation at #{Time.now.to_s}\n\n"

				file << "#ifndef #{@config.generated_file_name}_gen_h\n"
				file << "#define #{@config.generated_file_name}_gen_h\n\n"

				file << "#define #{@config.config_macro_name} @{\\\n"
				@anno_infos_dic.each do |file_path,array_for_file|
					file << "@\"#{file_path}\":@[\\\n"

					array_for_file.each do |anno_dic|
						file << "@{\\\n"

						file << "\t@\"className\":@\"#{anno_dic[ANNO_INFO_KEY_CLASS_NAME]}\",\\\n"

						file << "\t@\"position\":@\"#{anno_dic[ANNO_INFO_KEY_POSITION]}\",\\\n"

						file << "\t@\"type\":@\"#{anno_dic['type']}\",\\\n"

						unless anno_dic[ANNO_INFO_KEY_PROPERTY_NAME].nil?	
							file << "\t@\"propertyName\":@\"#{anno_dic[ANNO_INFO_KEY_PROPERTY_NAME]}\",\\\n"
						end

						unless anno_dic[ANNO_INFO_KEY_SELECTOR].nil?	
							file << "\t@\"methodSelector\":@\"#{anno_dic[ANNO_INFO_KEY_SELECTOR]}\",\\\n"
						end

						file << "\t@\"params\":@{\\\n"
						anno_dic[ANNO_INFO_KEY_PARAMS].each do |paramKey, paramValue|
							file << "\t\t@\"#{paramKey}\":@\"#{paramValue}\",\\\n"
						end
						file << "\t},\\\n"

						file << "},\\\n"
					end
					file << "],\\\n"
				end
				file << "}\n"

				file << "#endif \n"
			}
		end

		def deploy
			copy_target_path = Dir.pwd + "/#{@config.generated_file_name_with_ext}"
			FileUtils.cp(@generate_file_path, copy_target_path)
		end
		
		def prepare_to_generate_file
			#clear current config

			@annotations.each do |anno|
				array_for_file = @anno_infos_dic[anno.file_path]
				if array_for_file.nil?
					array_for_file = Array.new
					@anno_infos_dic[anno.file_path] = array_for_file
				else
					array_for_file.clear
				end
			end

			@annotations.each do |anno|
				array_for_file = @anno_infos_dic[anno.file_path]

				anno_dic = Hash.new
				anno_dic[ANNO_INFO_KEY_TYPE] = anno.type
				anno_dic[ANNO_INFO_KEY_POSITION] = anno.position
				anno_dic[ANNO_INFO_KEY_PARAMS] = anno.params
				anno_dic[ANNO_INFO_KEY_CLASS_NAME] = anno.class_name
				method_selector = anno.method_selector
				unless method_selector.nil?
					anno_dic[ANNO_INFO_KEY_SELECTOR] = method_selector
				end

				property_name = anno.property_name
				unless property_name.nil?
					anno_dic[ANNO_INFO_KEY_PROPERTY_NAME] = property_name
				end
				array_for_file.push(anno_dic)
			end
			
			print "#{@annotations.count} annotations found (counting modified or newly added since last build) \n"
		end

		def generate_cache_file
			GlobalConfig.save_to_file(@config.build_info_cache_path, @anno_infos_dic)
		end
	end
end