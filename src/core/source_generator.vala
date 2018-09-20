namespace Shady.Core
{
	public class SourceGenerator
	{
		private const string _channel_string = "iChannel";
		private static string _shader_prefix; 
		private static string _shader_suffix;

		static construct
		{
			try
			{
				_shader_prefix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data());
				_shader_suffix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/suffix.glsl", 0).get_data());
			}
			catch (Error e)
			{
				print("Couldn't load shader prefix or suffix\n");
			}
		}

		public SourceGenerator()
		{
		}

		public static HashTable<string, string> generate_shader_source(Shader shader)
		{
			HashTable<string, string> string_table = new HashTable<string, string>(str_hash, str_equal);
			for(int i=0;i<shader.renderpasses.length;i++)
			{
				Shader.Renderpass renderpass = shader.renderpasses.index(i);
				string_table.insert(renderpass.name, generate_renderpass_source(renderpass));
			}

			return string_table;
		}

		public static string generate_renderpass_source(Shader.Renderpass renderpass)
		{
			string channel_prefix = "";

			for(int i=0;i<renderpass.inputs.length;i++)
			{
				int index = renderpass.inputs.index(i).channel;
				if(renderpass.inputs.index(i).type == Shader.InputType.TEXTURE || renderpass.inputs.index(i).type == Shader.InputType.BUFFER)
				{
					channel_prefix += "uniform sampler2D " + _channel_string + @"$index;\n";
				}
				else if(renderpass.inputs.index(i).type == Shader.InputType.3DTEXTURE)
				{
					channel_prefix += "uniform sampler3D " + _channel_string + @"$index;\n";
				}
				else if(renderpass.inputs.index(i).type == Shader.InputType.CUBEMAP)
				{
					channel_prefix += "uniform samplerCube " + _channel_string + @"$index;\n";
				}
			}

			return _shader_prefix + channel_prefix + renderpass.code + _shader_suffix;
		}
	}
}