#include <pybind11/pybind11.h>
#include <pybind11/eigen.h>
#include <pybind11/stl.h>
#include <pybind11/stl_bind.h>
#include <pose.hpp>
#include <examples.hpp>
#include <vector>
#include <array>
#include <map>


namespace py = pybind11;

PYBIND11_DECLARE_HOLDER_TYPE(T, std::shared_ptr<T>);
PYBIND11_MODULE(pycpp_examples, m) {
    m.doc() = R"pbdoc(
        Pybind11 plugin for demonstrating C++ features
        -----------------------

        .. currentmodule:: pycpp_examples

        .. autosummary::
           :toctree: _generate

    )pbdoc";

    py::class_<Pose, std::shared_ptr<Pose>>(m, "Pose")
        .def(py::init<double, double, double>(),
             py::arg("x"), py::arg("y"), py::arg("yaw") = 0)
        .def_readwrite("x", &Pose::x)
        .def_readwrite("y", &Pose::y)
        .def_readwrite("yaw", &Pose::yaw)
        .def_readwrite("index", &Pose::index)
        .def("__rmul__", &Pose::rmul)
        .def("__mul__", &Pose::mul)
        .def_static("get_odom", &Pose::get_odom,
                    py::arg("p_new"), py::arg("p_old"));

    m.def("sqrt_sum_vec", &sqrt_sum_vec);

#ifdef VERSION_INFO
    m.attr("__version__") = VERSION_INFO;
#else
    m.attr("__version__") = "dev";
#endif
}
