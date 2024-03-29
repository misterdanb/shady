using GL;

namespace Shady.Core
{
	public class RenderResources
	{
		public class BufferProperties
		{
			public GLuint program;
			public GLuint fb;
			public GLuint vao;

			public GLuint tex_id_out_front;
			public GLuint tex_id_out_back;

			public Gdk.GLContext context;

			public GLuint[] tex_ids;
			public GLuint[] sampler_ids;
			public GLuint[] tex_targets;
			public int[] tex_channels;

			public int[,] tex_out_refs;

			public int[] tex_widths;
			public int[] tex_heights;
			public int[] tex_depths;

			public GLuint tile_render_buf;

			public int cur_x_img_part;
			public int cur_y_img_part;

			public uint x_img_parts;
			public uint y_img_parts;

			public bool second_resize;

			public bool parts_rendered;
			public bool updated;

			public int frame_counter;
			
			public double time;
			public double delta;

			public double tile_time_max;
			public double tile_time_sum;

			public float year;
			public float month;
			public float day;
			public float seconds;

			public int64 curr_time;
			public int64 time_delta;

			//public double[] tex_times;

			public GLint date_loc;
			public GLint time_loc;
			public GLint channel_time_loc;
			public GLint delta_loc;
			public GLint fps_loc;
			public GLint frame_loc;
			public GLint res_loc;
			public GLint channel_res_loc;
			public GLint mouse_loc;
			public GLint samplerate_loc;
			public GLint[] channel_locs;
			public GLint offset_loc;
		}

		public enum Purpose
		{
			COMPILE,
			RENDER;
		}

		public signal bool render();
		public signal bool update();

		private bool _buffer_switch = false;

		public Mutex buffer_switch_mutex = Mutex();

		private BufferProperties[] _buffer_props1 = {};
		private BufferProperties[] _buffer_props2 = {};

		private uint _image_prop_index1;
		private uint _image_prop_index2;

		private const uint _timeout_interval=16;

		private uint _render_timeout;

		private static uint _num_render_timeouts = 0;

		private const double _effective_target_time = 10000.0;
		private const double _effective_upper_time_threshold = 15000.0;
		private const double _effective_lower_time_threshold = 5000.0;

		public static double target_time = _effective_target_time;
		public static double upper_time_threshold = _effective_upper_time_threshold;
		public static double lower_time_threshold = _effective_lower_time_threshold;

		public bool update_wanted = false;
		public bool updated_once = false;

		private static Queue<RenderResources> _waiting_resources = new Queue<RenderResources>();

		public RenderResources()
		{
	 	}

		public BufferProperties get_image_prop(Purpose purpose)
		{
			if (!_buffer_switch && purpose == Purpose.RENDER || _buffer_switch && purpose == Purpose.COMPILE)
			{
				return _buffer_props1[_image_prop_index1];
			}
			else
			{
				return _buffer_props2[_image_prop_index2];
			}
		}

		public uint get_image_prop_index(Purpose purpose)
		{
			if (!_buffer_switch && purpose == Purpose.RENDER || _buffer_switch && purpose == Purpose.COMPILE)
			{
				return _image_prop_index1;
			}
			else
			{
				return _image_prop_index2;
			}
		}

		public void set_image_prop_index(Purpose purpose, uint index)
		{
			if (!_buffer_switch && purpose == Purpose.RENDER || _buffer_switch && purpose == Purpose.COMPILE)
			{
				_image_prop_index1 = index;
			}
			else
			{
				_image_prop_index2 = index;
			}
		}

		public BufferProperties[] get_buffer_props(Purpose purpose)
		{
			if (!_buffer_switch && purpose == Purpose.RENDER || _buffer_switch && purpose == Purpose.COMPILE)
			{
				return _buffer_props1;
			}
			else
			{
				return _buffer_props2;
			}
		}

		public void set_buffer_props(Purpose purpose, BufferProperties[] buffer_props)
		{
			if (!_buffer_switch && purpose == Purpose.RENDER || _buffer_switch && purpose == Purpose.COMPILE)
			{
				_buffer_props1 = buffer_props;
			}
			else
			{
				_buffer_props2 = buffer_props;
			}
		}

		public void switch_buffer()
		{
			buffer_switch_mutex.lock();
			_buffer_switch=!_buffer_switch;
			buffer_switch_mutex.unlock();
		}

		public void update_target_time()
		{
			double divisor = 1.0;

			if(_num_render_timeouts > 0)
			{
				divisor = _num_render_timeouts;
			}

			target_time = _effective_target_time / divisor;
			upper_time_threshold = _effective_upper_time_threshold / divisor;
			lower_time_threshold = _effective_lower_time_threshold / divisor;
		}

		public void add_render_timeout()
		{
			_render_timeout = Timeout.add(_timeout_interval, render_func);
			_num_render_timeouts++;

			update_target_time();
		}

		public void remove_render_timeout()
		{
			Source.remove(_render_timeout);
			_num_render_timeouts--;

			update_target_time();
		}

		public void add_update_timeout()
		{
			if(!update_wanted)
			{
				update_wanted = true;

				if(_waiting_resources.is_empty())
				{
					Timeout.add(_timeout_interval, update_func);
				}
				_waiting_resources.push_tail(this);
			}
		}

		public static void update_done()
		{
			if(!_waiting_resources.is_empty())
			{
				RenderResources updated_resource = _waiting_resources.peek_head();
				if(!updated_resource.updated_once)
				{
					updated_resource.updated_once = true;
					Timeout.add(_timeout_interval, updated_resource.update_func);
				}
				else
				{
					_waiting_resources.pop_head();
					updated_resource.update_wanted = false;
					updated_resource.updated_once = false;
					if(!_waiting_resources.is_empty())
					{
						RenderResources next_resource = _waiting_resources.pop_head();
						Timeout.add(_timeout_interval, next_resource.update_func);
					}
				}
			}
		}

		public bool render_func()
		{
			return render();
		}

		public bool update_func()
		{
			return update();
		}
	}
}
