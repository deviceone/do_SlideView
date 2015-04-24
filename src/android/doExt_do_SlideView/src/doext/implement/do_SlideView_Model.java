package doext.implement;

import java.util.Map;

import core.helper.jsonparse.DoJsonValue;
import core.interfaces.DoIListData;
import doext.define.do_SlideView_MAbstract;

/**
 * 自定义扩展组件Model实现，继承do_SlideView_MAbstract抽象类；
 *
 */
public class do_SlideView_Model extends do_SlideView_MAbstract {

	public do_SlideView_Model() throws Exception {
		super();
	}
	
	@Override
	public void setModelData(Map<String, DoJsonValue> _bindParas, Object _obj) throws Exception {
		if (_obj instanceof DoIListData) {
			do_SlideView_View _view = (do_SlideView_View) this.getCurrentUIModuleView();
			_view.setModelData(_obj);
			return;
		}
		super.setModelData(_bindParas, _obj);
	}
	
}
